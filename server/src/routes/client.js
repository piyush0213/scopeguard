import { Router } from 'express';
import { requireRole, HttpError } from '../auth.js';
import { one, many, query } from '../db.js';
import { generateQuestions, generateQuote } from '../ai.js';
import { createCheckout, settleSessionById, syncOrderPayments } from '../payments.js';
import { emit } from '../realtime.js';
import {
  getOrder, listOrders, loadOrderFor, broadcastOrder, insertMessage, totalOf, scopeHash, setStage,
} from '../services.js';

export const clientRouter = Router();
const client = requireRole('client');

clientRouter.get('/menu', async (_req, res) => {
  res.json({ items: await many('SELECT * FROM sg_menu_items ORDER BY price_cents') });
});

clientRouter.get('/client/orders', client, async (req, res) => {
  res.json({ orders: await listOrders('WHERE o.client_id=$1', [req.user.id]) });
});

// ---------------------------------------------------------------- Unified "New Project" ordering
// Every order starts with a project brief. Menu items and custom requests live in the same cart:
//   menu only            -> POST /orders/menu          -> instant fixed-price Stripe checkout
//   custom (+ any menu)  -> POST /orders/custom/scope  -> AI questions -> AI quote (menu items pre-priced) -> dev review

const MIN_BRIEF = 15;
function cleanBrief(text) {
  const t = String(text || '').trim();
  if (t.length < MIN_BRIEF) throw new HttpError(400, 'Tell us about your project in a sentence or two first');
  if (t.length > 3000) throw new HttpError(400, 'Project brief is too long (max 3000 characters)');
  return t;
}

async function loadMenuItems(ids) {
  const unique = [...new Set(ids || [])];
  if (!unique.length) return [];
  const items = await many('SELECT * FROM sg_menu_items WHERE id = ANY($1) ORDER BY price_cents', [unique]);
  if (items.length !== unique.length) throw new HttpError(400, 'Unknown menu item in cart');
  return items;
}

const menuModules = (items) =>
  items.map((it) => ({
    id: `menu-${it.id}`,
    name: it.name,
    description: it.description,
    price_cents: it.price_cents,
    optional: false,
    included: true,
    menu: true,
  }));

const shortTitle = (text, fallback) => {
  const firstLine = text.split(/[.\n]/)[0].trim();
  return (firstLine.length > 4 ? firstLine : fallback).slice(0, 60);
};

clientRouter.post('/orders/menu', client, async (req, res) => {
  const projectBrief = cleanBrief(req.body?.projectBrief);
  const items = await loadMenuItems(req.body?.itemIds);
  if (!items.length) throw new HttpError(400, 'Cart is empty');

  const modules = menuModules(items);
  const brief = {
    title: shortTitle(projectBrief, items.map((i) => i.name).join(' + ')),
    summary: projectBrief,
    in_scope: items.map((i) => `${i.name}: ${i.description}`),
    out_of_scope: ['Anything not described in the selected menu items', 'Custom features or integrations beyond the listed items'],
    timeline_days: Math.max(...items.map((i) => i.eta_days)),
  };
  const order = await one(
    `INSERT INTO sg_orders (client_id,title,type,status,total_cents,scoping_json)
     VALUES ($1,$2,'menu','awaiting_payment',$3,$4) RETURNING id`,
    [req.user.id, brief.title, totalOf(modules), { idea: projectBrief, menuItemIds: items.map((i) => i.id) }],
  );
  await query(
    `INSERT INTO sg_quotes (order_id,brief_json,modules_json,status) VALUES ($1,$2,$3,'negotiating')`,
    [order.id, brief, JSON.stringify(modules)],
  );
  const full = await getOrder(order.id);
  const me = await one('SELECT email FROM sg_users WHERE id=$1', [req.user.id]);
  const session = await createCheckout({
    order: full,
    kind: 'initial',
    snapshot: { modules },
    customerEmail: me.email,
    returnUrl: req.body?.returnUrl,
    lineItems: modules.map((m) => ({ name: m.name, description: m.description, amountCents: m.price_cents })),
  });
  await broadcastOrder(order.id);
  res.status(201).json({ orderId: order.id, checkoutUrl: session.url });
});

clientRouter.post('/orders/custom/scope', client, async (req, res) => {
  const { orderId, answers } = req.body || {};

  // Step 1: brief + custom request (+ optional menu items) -> clarifying questions.
  if (!orderId) {
    const projectBrief = cleanBrief(req.body?.projectBrief ?? req.body?.prompt);
    const custom = String(req.body?.customRequest || '').trim();
    if (req.body?.customRequest !== undefined && custom.length < 8) {
      throw new HttpError(400, 'Describe the custom feature you want');
    }
    const items = await loadMenuItems(req.body?.menuItemIds);
    const ai = await generateQuestions(projectBrief, { custom: custom || projectBrief, menuItems: items });
    const order = await one(
      `INSERT INTO sg_orders (client_id,title,type,status,scoping_json) VALUES ($1,$2,'custom','scoping',$3) RETURNING id`,
      [req.user.id, ai.title || 'Custom project', { idea: projectBrief, custom, menuItemIds: items.map((i) => i.id), questions: ai.questions }],
    );
    return res.status(201).json({ orderId: order.id, title: ai.title, questions: ai.questions });
  }

  // Step 2: answers -> brief + modules. Menu items are added as fixed-price core modules.
  const order = await loadOrderFor(req.user, orderId);
  if (order.status !== 'scoping') throw new HttpError(409, 'This order has already been scoped');
  const qs = order.scoping.questions || [];
  if (!Array.isArray(answers) || answers.length !== qs.length || answers.some((a) => !String(a || '').trim())) {
    throw new HttpError(400, 'Please answer every question');
  }
  const qa = qs.map((q, i) => ({ question: q.question, answer: String(answers[i]).trim() }));
  const items = await loadMenuItems(order.scoping.menuItemIds);
  const ai = await generateQuote(order.scoping.idea, qa, { custom: order.scoping.custom || order.scoping.idea, menuItems: items });

  const fixed = menuModules(items);
  const fixedNames = new Set(fixed.map((m) => m.name.toLowerCase()));
  const modules = [...fixed, ...ai.modules.filter((m) => !fixedNames.has(m.name.toLowerCase()))];
  const brief = { ...ai.brief };
  for (const it of [...items].reverse()) {
    if (!(brief.in_scope || []).some((x) => x.toLowerCase().includes(it.name.toLowerCase()))) {
      brief.in_scope = [`${it.name}: ${it.description}`, ...(brief.in_scope || [])];
    }
  }
  if (items.length) brief.timeline_days = Math.max(brief.timeline_days || 0, ...items.map((i) => i.eta_days));

  await query(
    `INSERT INTO sg_quotes (order_id,brief_json,modules_json,status) VALUES ($1,$2,$3,'ai_draft')
     ON CONFLICT (order_id) DO UPDATE SET brief_json=EXCLUDED.brief_json, modules_json=EXCLUDED.modules_json, status='ai_draft'`,
    [order.id, brief, JSON.stringify(modules)],
  );
  await query(
    `UPDATE sg_orders SET status='ai_draft', title=$2, total_cents=$3, scoping_json = scoping_json || $4::jsonb, updated_at=now() WHERE id=$1`,
    [order.id, brief.title || order.title, totalOf(modules), JSON.stringify({ qa })],
  );
  const customCount = modules.length - fixed.length;
  await insertMessage({
    orderId: order.id,
    senderRole: 'system',
    content: `🤖 AI drafted a quote: ${fixed.length ? `${fixed.length} menu item${fixed.length > 1 ? 's' : ''} + ` : ''}${customCount} custom module${customCount === 1 ? '' : 's'}. A developer is reviewing it now.`,
  });
  const updated = await broadcastOrder(order.id);
  emit.toDevs('quote:new', updated);
  res.json({ order: updated });
});

// Client toggles optional modules on a negotiating quote (dev sees totals live).
clientRouter.patch('/orders/:id/toggles', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  if (order.quote?.status !== 'negotiating' || order.paid) throw new HttpError(409, 'Quote is not open for changes');
  const wanted = new Map((req.body?.modules || []).map((m) => [m.id, !!m.included]));
  const modules = order.quote.modules.map((m) => (m.optional && wanted.has(m.id) ? { ...m, included: wanted.get(m.id) } : m));
  await query('UPDATE sg_quotes SET modules_json=$2, updated_at=now() WHERE id=$1', [order.quote.id, JSON.stringify(modules)]);
  await query('UPDATE sg_orders SET total_cents=$2, updated_at=now() WHERE id=$1', [order.id, totalOf(modules)]);
  res.json({ order: await broadcastOrder(order.id) });
});

// Client modifies order items (menu items + custom features) after placing
clientRouter.patch('/orders/:id/modify', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  const { menuItemIds, customRequest, projectBrief } = req.body || {};

  // Case 1: Pre-pay order (scoping, ai_draft, negotiating, awaiting_payment)
  if (!order.paid) {
    const items = await loadMenuItems(menuItemIds);
    const newMenuMods = menuModules(items);
    const existingModules = order.quote?.modules || [];
    let updatedCustomMods = existingModules.filter((m) => !m.menu);

    const briefText = projectBrief ? cleanBrief(projectBrief) : (order.quote?.brief?.summary || order.scoping?.idea || 'Client project');
    const customText = customRequest !== undefined ? String(customRequest).trim() : (order.scoping?.custom || '');

    if (customRequest !== undefined && customText.length >= 8 && (!updatedCustomMods.length || customText !== order.scoping?.custom)) {
      try {
        const ai = await generateQuote(briefText, [{ question: 'What custom additions are required?', answer: customText }], {
          custom: customText,
          menuItems: items,
        });
        const fixedNames = new Set(newMenuMods.map((m) => m.name.toLowerCase()));
        updatedCustomMods = (ai.modules || []).filter((m) => !fixedNames.has(m.name.toLowerCase()));
      } catch {
        updatedCustomMods = [
          {
            id: `custom-${Date.now().toString(36)}`,
            name: customText.slice(0, 32),
            description: customText,
            price_cents: 35000,
            optional: false,
            included: true,
          },
        ];
      }
    } else if (customRequest !== undefined && !customText) {
      // Client explicitly cleared custom requests
      updatedCustomMods = [];
    }

    const finalModules = [...newMenuMods, ...updatedCustomMods];
    if (!finalModules.length) throw new HttpError(400, 'Order cannot be empty. Select at least one item or custom request.');

    const brief = {
      ...(order.quote?.brief || {}),
      title: shortTitle(briefText, items.map((i) => i.name).concat(updatedCustomMods.map((m) => m.name)).join(' + ') || order.title),
      summary: briefText,
      in_scope: [
        ...items.map((i) => `${i.name}: ${i.description}`),
        ...updatedCustomMods.map((m) => `${m.name}: ${m.description || 'Custom feature'}`),
      ],
      out_of_scope: order.quote?.brief?.out_of_scope || ['Anything not explicitly listed in the scope modules'],
      timeline_days: Math.max(...(items.map((i) => i.eta_days).concat([order.quote?.brief?.timeline_days || 3]))),
    };

    const newVersion = (order.quote?.version || 1) + 1;
    await query(
      `UPDATE sg_quotes SET brief_json=$2, modules_json=$3, version=$4, updated_at=now() WHERE id=$1`,
      [order.quote.id, brief, JSON.stringify(finalModules), newVersion]
    );

    const newTotal = totalOf(finalModules);
    await query(
      `UPDATE sg_orders SET total_cents=$2, title=$3, scoping_json = scoping_json || $4::jsonb, updated_at=now() WHERE id=$1`,
      [order.id, newTotal, brief.title, JSON.stringify({ idea: briefText, custom: customText, menuItemIds: items.map((i) => i.id) })]
    );

    const changeSummary = `${items.length} menu item${items.length === 1 ? '' : 's'}${updatedCustomMods.length ? ` + ${updatedCustomMods.length} custom` : ''}`;
    await insertMessage({
      orderId: order.id,
      senderRole: 'system',
      content: `📝 Client updated the order scope (${changeSummary}). Bill updated to $${(newTotal / 100).toFixed(2)}.`,
    });

    const updated = await broadcastOrder(order.id);
    emit.toDevs('quote:new', updated);
    return res.json({ order: updated });
  }

  // Case 2: Paid & Active order (stages 0 to 5)
  if (order.paid && order.stage <= 5) {
    const existingMenuIds = new Set(
      (order.quote?.modules || [])
        .filter((m) => m.menu)
        .map((m) => m.id.replace(/^menu-/, ''))
    );
    const addedIds = (menuItemIds || []).filter((id) => !existingMenuIds.has(id));
    const customText = String(customRequest || '').trim();

    if (!addedIds.length && (!customText || customText.length < 8)) {
      throw new HttpError(400, 'Please select new items to add or enter a custom request of at least 8 characters.');
    }

    let addonTitle = '';
    let addonDesc = '';
    let addonPriceCents = 0;

    if (addedIds.length > 0) {
      const addedItems = await loadMenuItems(addedIds);
      const names = addedItems.map((i) => i.name).join(' + ');
      const sumCents = addedItems.reduce((acc, i) => acc + i.price_cents, 0);
      addonTitle = names;
      addonDesc = addedItems.map((i) => `${i.name} ($${(i.price_cents / 100).toFixed(2)})`).join(', ');
      addonPriceCents += sumCents;
    }

    if (customText && customText.length >= 8) {
      if (addonTitle) {
        addonTitle += ` + Custom: ${customText.slice(0, 24)}…`;
        addonDesc += ` | Custom: ${customText}`;
      } else {
        addonTitle = customText.slice(0, 40);
        addonDesc = customText;
      }
      addonPriceCents += 35000; // estimated $350 for custom component
    }

    const msg = await insertMessage({
      orderId: order.id,
      senderRole: 'client',
      type: 'scope_addon',
      content: `I would like to add this to the build: "${addonTitle}" ($${(addonPriceCents / 100).toFixed(2)}).`,
      metadata: {
        title: addonTitle,
        description: addonDesc,
        priceCents: addonPriceCents,
        status: 'offered',
        clientRequested: true,
      },
    });

    await insertMessage({
      orderId: order.id,
      senderRole: 'system',
      content: `⚡ Order change request created for "${addonTitle}" ($${(addonPriceCents / 100).toFixed(2)}). Ready for payment or developer review.`,
    });

    const updated = await broadcastOrder(order.id);
    return res.json({ order: updated, addonMessageId: msg.id });
  }

  throw new HttpError(400, 'Order cannot be modified in its current stage');
});


clientRouter.post('/orders/:id/checkout', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  if (order.paid) throw new HttpError(409, 'Order already paid');
  if (!['negotiating', 'awaiting_payment'].includes(order.status)) throw new HttpError(409, 'Quote has not been approved by a developer yet');
  if (req.body?.quoteVersion && req.body.quoteVersion !== order.quote.version) {
    throw new HttpError(409, 'The developer just revised this quote. Please review the new version.');
  }
  const modules = order.quote.modules.map((m) => (m.optional ? m : { ...m, included: true }));
  const chosen = modules.filter((m) => m.included);
  const hash = scopeHash(order.quote.brief, modules);
  await query('UPDATE sg_orders SET scope_hash=$2, total_cents=$3, updated_at=now() WHERE id=$1', [order.id, hash, totalOf(modules)]);
  const me = await one('SELECT email FROM sg_users WHERE id=$1', [req.user.id]);
  const session = await createCheckout({
    order,
    kind: 'initial',
    snapshot: { modules, version: order.quote.version, hash },
    customerEmail: me.email,
    returnUrl: req.body?.returnUrl,
    lineItems: chosen.map((m) => ({ name: m.name, description: m.description, amountCents: m.price_cents })),
  });
  res.json({ checkoutUrl: session.url, scopeHash: hash });
});

clientRouter.post('/orders/:id/addons/:addonId/pay', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  const m = await one(`SELECT * FROM sg_messages WHERE id=$1 AND order_id=$2 AND type='scope_addon'`, [req.params.addonId, order.id]);
  if (!m) throw new HttpError(404, 'Add-on not found');
  if (m.metadata_json.status !== 'offered') throw new HttpError(409, `Add-on is already ${m.metadata_json.status}`);
  const me = await one('SELECT email FROM sg_users WHERE id=$1', [req.user.id]);
  const session = await createCheckout({
    order,
    kind: 'addon',
    addonMessageId: m.id,
    customerEmail: me.email,
    returnUrl: req.body?.returnUrl,
    lineItems: [{ name: `Add-on: ${m.metadata_json.title}`, description: m.metadata_json.description, amountCents: m.metadata_json.priceCents }],
  });
  res.json({ checkoutUrl: session.url });
});

clientRouter.post('/orders/:id/addons/:addonId/skip', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  const m = await one(
    `UPDATE sg_messages SET metadata_json = metadata_json || '{"status":"skipped"}'::jsonb
     WHERE id=$1 AND order_id=$2 AND type='scope_addon' AND metadata_json->>'status'='offered' RETURNING metadata_json`,
    [req.params.addonId, order.id],
  );
  if (!m) throw new HttpError(409, 'Add-on cannot be skipped');
  emit.toOrder(order.id, 'chat:updated', { id: req.params.addonId, metadata: m.metadata_json });
  await insertMessage({ orderId: order.id, senderRole: 'system', content: `Client skipped add-on "${m.metadata_json.title}". Original scope unchanged.` });
  res.json({ ok: true });
});

clientRouter.post('/orders/:id/client-accept', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  if (order.stage !== 6) throw new HttpError(409, 'Order is not delivered yet');
  const updated = await setStage(order.id, 7, { note: '🎉 Client accepted the delivery. Order completed!' });
  res.json({ order: updated });
});

// Called on return from Stripe Checkout; verifies with Stripe server-side (works even without webhooks).
clientRouter.post('/payments/verify', client, async (req, res) => {
  const sessionId = req.body?.sessionId;
  const pay = sessionId && (await one('SELECT order_id FROM sg_payments WHERE stripe_session_id=$1', [sessionId]));
  if (!pay) throw new HttpError(404, 'Unknown checkout session');
  await loadOrderFor(req.user, pay.order_id);
  const result = await settleSessionById(sessionId);
  res.json({ ...result, order: await getOrder(pay.order_id) });
});

// Asks Stripe about this order's open checkouts and settles any that are paid. Needs no session id, so it works
// after the app was reloaded or the payer paid on another device.
clientRouter.post('/orders/:id/payments/sync', client, async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  const result = order.paid ? { settled: true, alreadySettled: true } : await syncOrderPayments(order.id);
  res.json({ ...result, order: await getOrder(order.id) });
});
