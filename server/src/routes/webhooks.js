import express, { Router } from 'express';
import crypto from 'node:crypto';
import { config } from '../config.js';
import { one, many } from '../db.js';
import { stripe, settleSession } from '../payments.js';
import { verifySignature, applyGithubEvent, branchOf } from '../github.js';
import { requireAuth, requireRole, HttpError } from '../auth.js';
import { getOrder } from '../services.js';

export const webhookRouter = Router();
const raw = express.raw({ type: '*/*', limit: '5mb' });

webhookRouter.post('/webhooks/stripe', raw, async (req, res) => {
  let event;
  try {
    if (config.stripeWebhookSecret) {
      event = stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'], config.stripeWebhookSecret);
    } else {
      // No signing secret configured: never trust the body, re-fetch the session from Stripe instead.
      const body = JSON.parse(req.body.toString('utf8'));
      if (body?.type !== 'checkout.session.completed') return res.json({ received: true, ignored: true });
      const session = await stripe.checkout.sessions.retrieve(body.data.object.id);
      event = { type: body.type, data: { object: session } };
    }
  } catch (e) {
    console.warn('[stripe] webhook rejected:', e.message);
    return res.status(400).send(`Webhook Error: ${e.message}`);
  }
  if (['checkout.session.completed', 'checkout.session.async_payment_succeeded'].includes(event.type)) {
    const r = await settleSession(event.data.object);
    console.log(`[stripe] ${event.type} ${event.data.object.id} ->`, r.alreadySettled ? 'already settled' : r.settled ? 'settled' : r.reason);
  }
  res.json({ received: true });
});

/** Store a GitHub event once (by delivery id) and run it through the FSM. */
export async function ingestGithub(deliveryId, event, payload) {
  const branch = branchOf(event, payload);
  const order = branch ? await one('SELECT id FROM sg_orders WHERE branch_name=$1', [branch]) : null;
  const inserted = await one(
    `INSERT INTO sg_events (order_id,delivery_id,event_type,payload_json) VALUES ($1,$2,$3,$4)
     ON CONFLICT (delivery_id) DO NOTHING RETURNING id`,
    [order?.id || null, deliveryId, event, payload],
  );
  if (!inserted) return { duplicate: true };
  return applyGithubEvent(event, payload);
}

webhookRouter.post('/webhooks/github', raw, async (req, res) => {
  if (!config.githubWebhookSecret) return res.status(503).send('GITHUB_WEBHOOK_SECRET not configured');
  if (!verifySignature(req.body, req.headers['x-hub-signature-256'])) return res.status(401).send('Bad signature');
  const event = req.headers['x-github-event'];
  const delivery = req.headers['x-github-delivery'];
  if (!event || !delivery) return res.status(400).send('Missing GitHub headers');
  if (event === 'ping') return res.json({ ok: true, pong: true });
  const payload = JSON.parse(req.body.toString('utf8'));
  const result = await ingestGithub(delivery, event, payload);
  console.log(`[github] ${event}${payload.action ? '.' + payload.action : ''} ${delivery} ->`, result);
  res.json(result);
});

// ---------- Demo failsafe: re-fire recorded GitHub payloads through the same FSM ----------
const REPLAY = {
  2: { event: 'create', match: `event_type='create'` },
  3: { event: 'workflow_run', match: `event_type='workflow_run' AND payload_json->'workflow_run'->>'conclusion'='success'` },
  ci_fail: { event: 'workflow_run', match: `event_type='workflow_run' AND payload_json->'workflow_run'->>'conclusion'='failure'` },
  4: { event: 'pull_request', match: `event_type='pull_request' AND payload_json->>'action'='opened'` },
  5: { event: 'deployment_status', match: `event_type='deployment_status' AND payload_json->'deployment_status'->>'state'='success'` },
  6: { event: 'pull_request', match: `event_type='pull_request' AND payload_json->>'action'='closed' AND (payload_json->'pull_request'->>'merged')::boolean` },
};

async function fixture(stage) {
  const mod = await import(`../../fixtures/github.js`);
  return mod.fixtures[stage];
}

webhookRouter.get('/demo/replay/:orderId', requireAuth, requireRole('dev'), async (req, res) => {
  const out = {};
  for (const [stage, def] of Object.entries(REPLAY)) {
    const rec = await one(`SELECT created_at FROM sg_events WHERE delivery_id NOT LIKE 'replay-%' AND ${def.match} ORDER BY created_at DESC LIMIT 1`);
    out[stage] = rec ? 'recorded' : 'fixture';
  }
  const recent = await many(
    `SELECT delivery_id, event_type, payload_json->>'action' AS action, created_at FROM sg_events WHERE order_id=$1 ORDER BY created_at DESC LIMIT 20`,
    [req.params.orderId],
  );
  res.json({ sources: out, recent });
});

webhookRouter.post('/demo/replay/:orderId/:stage', requireAuth, requireRole('dev'), async (req, res) => {
  const order = await getOrder(req.params.orderId);
  if (!order) throw new HttpError(404, 'Order not found');
  if (!order.paid) throw new HttpError(409, 'Order must be paid first');
  const def = REPLAY[req.params.stage];
  if (!def) throw new HttpError(400, 'Replayable stages: 2, 3, ci_fail, 4, 5, 6');

  const rec = await one(
    `SELECT payload_json FROM sg_events WHERE delivery_id NOT LIKE 'replay-%' AND ${def.match} ORDER BY created_at DESC LIMIT 1`,
  );
  const source = rec ? 'recorded' : 'fixture';
  const template = rec?.payload_json || (await fixture(req.params.stage));
  const oldBranch = branchOf(def.event, template);
  // Re-target the recorded payload at this order's branch.
  const payload = JSON.parse(JSON.stringify(template).split(JSON.stringify(oldBranch).slice(1, -1)).join(order.branchName));
  const result = await ingestGithub(`replay-${crypto.randomUUID()}`, def.event, payload);
  res.json({ source, ...result, order: await getOrder(order.id) });
});
