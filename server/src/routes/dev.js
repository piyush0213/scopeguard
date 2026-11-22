import { Router } from 'express';
import { requireRole, HttpError } from '../auth.js';
import { one, many, query } from '../db.js';
import { syncOrderPayments } from '../payments.js';
import { listOrders, getOrder, broadcastOrder, insertMessage, totalOf, setStage } from '../services.js';
import { config } from '../config.js';
import { connectRepo, disconnectRepo, pollSoon } from '../github-sync.js';

export const devRouter = Router();
const dev = requireRole('dev');

devRouter.get('/dev/orders', dev, async (_req, res) => {
  // Orders with an open Stripe checkout from the last hour: confirm them with Stripe (throttled), so a client's
  // payment reaches the developer's queue even if the client closed the Stripe tab.
  const open = await many(
    `SELECT DISTINCT p.order_id FROM sg_payments p JOIN sg_orders o ON o.id=p.order_id
     WHERE p.status='pending' AND NOT o.paid AND p.created_at > now() - interval '1 hour' LIMIT 5`,
  );
  await Promise.all(open.map((r) => syncOrderPayments(r.order_id, { minIntervalMs: 10000 }).catch(() => {})));
  res.json({ orders: await listOrders(`WHERE o.status <> 'scoping'`) });
});

function cleanModules(input) {
  if (!Array.isArray(input) || !input.length) throw new HttpError(400, 'At least one module is required');
  return input.map((m, i) => {
    const price = Math.round(Number(m.price_cents));
    if (!m.name?.trim() || !Number.isFinite(price) || price < 0) throw new HttpError(400, `Module ${i + 1} is invalid`);
    return {
      id: m.id || `m${Date.now().toString(36)}${i}`,
      name: m.name.trim(),
      description: String(m.description || '').trim(),
      price_cents: price,
      optional: !!m.optional,
      included: m.included !== false,
      ...(m.menu ? { menu: true } : {}),
      ...(m.addon ? { addon: true } : {}),
    };
  });
}

async function loadQuote(id) {
  const q = await one('SELECT * FROM sg_quotes WHERE id=$1', [id]);
  if (!q) throw new HttpError(404, 'Quote not found');
  return q;
}

devRouter.patch('/quotes/:id/approve', dev, async (req, res) => {
  const q = await loadQuote(req.params.id);
  if (q.status !== 'ai_draft') throw new HttpError(409, 'Quote already approved');
  const modules = req.body?.modules ? cleanModules(req.body.modules) : q.modules_json;
  const brief = req.body?.brief || q.brief_json;
  await query(`UPDATE sg_quotes SET status='negotiating', modules_json=$2, brief_json=$3, updated_at=now() WHERE id=$1`, [
    q.id, JSON.stringify(modules), brief,
  ]);
  await query(`UPDATE sg_orders SET status='negotiating', dev_id=$2, total_cents=$3, updated_at=now() WHERE id=$1`, [
    q.order_id, req.user.id, totalOf(modules),
  ]);
  await insertMessage({
    orderId: q.order_id,
    senderId: req.user.id,
    senderRole: 'dev',
    type: 'quote_revision',
    content: `Quote v${q.version} approved and sent. Toggle optional modules, ask me anything, then Accept & Pay.`,
    metadata: { version: q.version, totalCents: totalOf(modules) },
  });
  res.json({ order: await broadcastOrder(q.order_id) });
});

devRouter.patch('/quotes/:id/revise', dev, async (req, res) => {
  const q = await loadQuote(req.params.id);
  if (q.status !== 'negotiating') throw new HttpError(409, 'Only negotiating quotes can be revised');
  const order = await one('SELECT paid FROM sg_orders WHERE id=$1', [q.order_id]);
  if (order.paid) throw new HttpError(409, 'Order already paid — use a ScopeGuard add-on instead');
  const before = q.modules_json;
  const modules = cleanModules(req.body?.modules);
  const version = q.version + 1;
  await query(`UPDATE sg_quotes SET modules_json=$2, version=$3, updated_at=now() WHERE id=$1`, [q.id, JSON.stringify(modules), version]);
  await query(`UPDATE sg_orders SET total_cents=$2, dev_id=COALESCE(dev_id,$3), updated_at=now() WHERE id=$1`, [
    q.order_id, totalOf(modules), req.user.id,
  ]);
  const changes = diffModules(before, modules);
  const updated = await broadcastOrder(q.order_id);
  await insertMessage({
    orderId: q.order_id,
    senderId: req.user.id,
    senderRole: 'dev',
    type: 'quote_revision',
    content: req.body?.note?.trim() || `Quote revised to v${version}.`,
    metadata: { version, totalCents: totalOf(modules), changes },
  });
  res.json({ order: updated });
});

function diffModules(a, b) {
  const byId = new Map(a.map((m) => [m.id, m]));
  const out = [];
  for (const m of b) {
    const old = byId.get(m.id);
    if (!old) out.push(`Added "${m.name}" ($${m.price_cents / 100})`);
    else {
      if (old.price_cents !== m.price_cents) out.push(`"${m.name}": $${old.price_cents / 100} → $${m.price_cents / 100}`);
      if (old.name !== m.name) out.push(`Renamed "${old.name}" → "${m.name}"`);
      byId.delete(m.id);
    }
  }
  for (const m of byId.values()) out.push(`Removed "${m.name}"`);
  return out;
}

devRouter.post('/orders/:id/accept', dev, async (req, res) => {
  const order = await getOrder(req.params.id);
  if (!order) throw new HttpError(404, 'Order not found');
  if (!order.paid || order.stage !== 0) throw new HttpError(409, 'Only paid & queued orders can be accepted');
  await query('UPDATE sg_orders SET dev_id=$2 WHERE id=$1', [order.id, req.user.id]);
  const updated = await setStage(order.id, 1, {
    note: `👍 ${req.user.name} accepted the order. Work starts on branch \`${order.branchName}\`.`,
  });
  pollSoon(order.id); // pick up anything already pushed to the linked repo
  res.json({ order: updated, git: gitInstructions(order.branchName, order.repoFullName || undefined, order.repoSync?.defaultBranch) });
});

devRouter.post('/orders/:id/addons', dev, async (req, res) => {
  const order = await getOrder(req.params.id);
  if (!order?.paid || order.stage > 5) throw new HttpError(409, 'Add-ons are only possible during an active build');
  const title = String(req.body?.title || '').trim();
  const priceCents = Math.round(Number(req.body?.priceCents));
  if (!title || !Number.isFinite(priceCents) || priceCents < 50) throw new HttpError(400, 'Title and a price of at least $0.50 are required');
  const msg = await insertMessage({
    orderId: order.id,
    senderId: req.user.id,
    senderRole: 'dev',
    type: 'scope_addon',
    content: `That's outside the locked scope, but I can add it: "${title}" for $${(priceCents / 100).toFixed(2)}.`,
    metadata: {
      title,
      description: String(req.body?.description || '').trim(),
      priceCents,
      status: 'offered',
      sourceMessageId: req.body?.sourceMessageId || null,
    },
  });
  res.status(201).json({ message: msg });
});

devRouter.post('/orders/:id/preview', dev, async (req, res) => {
  const order = await getOrder(req.params.id);
  if (!order?.paid) throw new HttpError(409, 'Order is not active');
  let url;
  try {
    url = new URL(String(req.body?.url || '')).toString();
  } catch {
    throw new HttpError(400, 'Enter a valid preview URL');
  }
  const updated = await setStage(order.id, 5, { set: { preview_url: url }, note: `😋 Taste Test — preview is live: ${url}` });
  res.json({ order: updated || (await getOrder(order.id)) });
});

devRouter.post('/orders/:id/repo', dev, async (req, res) => {
  res.json({ order: await connectRepo(req.params.id, req.body?.url) });
});

devRouter.delete('/orders/:id/repo', dev, async (req, res) => {
  res.json({ order: await disconnectRepo(req.params.id) });
});

export function gitInstructions(branch, repo = config.githubRepo, base = 'main') {
  return [
    repo ? `git clone https://github.com/${repo}.git && cd ${repo.split('/')[1]}` : null,
    `git checkout -b ${branch}`,
    `git commit --allow-empty -m "start ${branch}" && git push -u origin ${branch}`,
    `gh pr create --base ${base} --head ${branch} --fill`,
    `gh pr merge ${branch} --merge`,
  ].filter(Boolean);
}
