import Stripe from 'stripe';
import { config } from './config.js';
import { tx, one, many } from './db.js';
import { HttpError } from './auth.js';
import { scopeHash, totalOf, insertMessage, broadcastOrder, STAGES } from './services.js';
import { emit } from './realtime.js';
import { compileSoon } from './proof.js';

export const stripe = config.stripeKey ? new Stripe(config.stripeKey) : null;

function requireStripe() {
  if (!stripe) throw new HttpError(503, 'Stripe is not configured (STRIPE_SECRET_KEY)');
  return stripe;
}

/**
 * Where Stripe sends the payer back to. The Flutter app passes its own address so the payer lands back in the app;
 * only known ScopeGuard front ends are accepted (never an arbitrary site).
 */
export function safeReturnUrl(url) {
  if (!url || typeof url !== 'string') return null;
  try {
    const u = new URL(url);
    const host = u.hostname;
    const ok =
      (u.protocol === 'https:' && (host.endsWith('.serverpod.space') || host === new URL(config.appUrl).hostname)) ||
      (u.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(host)) ||
      (u.protocol === 'http:' && /^(10|192\.168|172\.(1[6-9]|2\d|3[01]))\./.test(host));
    return ok ? `${u.origin}${u.pathname.replace(/\/+$/, '')}/` : null;
  } catch {
    return null;
  }
}

/**
 * Create an immediate-capture Stripe Checkout Session and a pending payment row.
 * lineItems: [{ name, description, amountCents }]
 * returnUrl: optional front-end base (see safeReturnUrl); default is the website's order page.
 */
export async function createCheckout({ order, lineItems, kind, addonMessageId = null, snapshot = {}, customerEmail, returnUrl = null }) {
  const s = requireStripe();
  const amount = lineItems.reduce((sum, li) => sum + li.amountCents, 0);
  if (amount < 50) throw new HttpError(400, 'Order total must be at least $0.50');
  const session = await s.checkout.sessions.create({
    mode: 'payment',
    payment_intent_data: { capture_method: 'automatic', metadata: { orderId: order.id, kind } },
    customer_email: customerEmail || undefined,
    line_items: lineItems.map((li) => ({
      quantity: 1,
      price_data: {
        currency: config.currency,
        unit_amount: li.amountCents,
        product_data: { name: li.name.slice(0, 250), ...(li.description ? { description: li.description.slice(0, 500) } : {}) },
      },
    })),
    metadata: { orderId: order.id, kind, addonMessageId: addonMessageId || '' },
    ...(() => {
      const app = safeReturnUrl(returnUrl);
      return app
        ? {
            success_url: `${app}?paid=${order.id}&session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${app}?canceled=${order.id}`,
          }
        : {
            success_url: `${config.appUrl}/client/orders/${order.id}?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${config.appUrl}/client/orders/${order.id}?canceled=1`,
          };
    })(),
  });
  await one(
    `INSERT INTO sg_payments (order_id,stripe_session_id,amount_cents,kind,addon_message_id,snapshot_json,status)
     VALUES ($1,$2,$3,$4,$5,$6,'pending') RETURNING id`,
    [order.id, session.id, amount, kind, addonMessageId, snapshot],
  );
  return session;
}

/**
 * Ask Stripe about every open checkout of one order and settle the paid ones. This is what makes a payment
 * show up even if the payer never comes back from Stripe (closed tab, phone reloaded the app, no webhook).
 */
const lastSync = new Map();
export async function syncOrderPayments(orderId, { minIntervalMs = 0 } = {}) {
  if (!stripe) return { settled: false, reason: 'stripe not configured' };
  const now = Date.now();
  if (minIntervalMs && now - (lastSync.get(orderId) || 0) < minIntervalMs) return { settled: false, reason: 'throttled' };
  lastSync.set(orderId, now);
  const rows = await many(
    `SELECT stripe_session_id FROM sg_payments
     WHERE order_id=$1 AND status='pending' AND created_at > now() - interval '2 days'
     ORDER BY created_at DESC LIMIT 5`,
    [orderId],
  );
  let settled = false;
  let reason = rows.length ? 'not paid yet' : 'no open checkout';
  for (const r of rows) {
    try {
      const out = await settleSessionById(r.stripe_session_id);
      if (out.settled) settled = true;
      else reason = out.reason || reason;
    } catch (e) {
      reason = e.message;
    }
  }
  return { settled, reason: settled ? undefined : reason };
}

/** Fetch a session from Stripe and settle it if paid. Safe to call from webhook AND redirect concurrently. */
export async function settleSessionById(sessionId) {
  const s = requireStripe();
  const session = await s.checkout.sessions.retrieve(sessionId);
  return settleSession(session);
}

export async function settleSession(session) {
  if (session.payment_status !== 'paid') return { settled: false, reason: `payment_status=${session.payment_status}` };

  const result = await tx(async (c) => {
    // Atomically claim the pending payment so webhook + redirect can't double-apply.
    const { rows } = await c.query(
      `UPDATE sg_payments SET status='paid' WHERE stripe_session_id=$1 AND status='pending' RETURNING *`,
      [session.id],
    );
    const pay = rows[0];
    if (!pay) return null;
    const {
      rows: [quote],
    } = await c.query('SELECT * FROM sg_quotes WHERE order_id=$1 FOR UPDATE', [pay.order_id]);

    if (pay.kind === 'initial') {
      // Lock exactly what the client paid for (snapshot taken at checkout).
      const modules = pay.snapshot_json.modules || quote.modules_json;
      const brief = quote.brief_json;
      const hash = scopeHash(brief, modules);
      await c.query(
        `UPDATE sg_quotes SET status='locked', modules_json=$2, updated_at=now() WHERE id=$1`,
        [quote.id, JSON.stringify(modules)],
      );
      await c.query(
        `UPDATE sg_orders SET paid=true, status='paid', stage=0, scope_hash=$2, total_cents=$3,
           branch_name=COALESCE(branch_name, 'order/' || id),
           timeline_json = jsonb_build_object('0', now()), updated_at=now()
         WHERE id=$1`,
        [pay.order_id, hash, pay.amount_cents],
      );
      return { pay, hash, note: `💳 Payment of $${(pay.amount_cents / 100).toFixed(2)} received. Scope locked (${hash.slice(0, 12)}…). Order is ${STAGES[0].label}.` };
    }

    // Add-on: append a module, bump version, re-hash, mark the chat card as paid.
    const { rows: [m] } = await c.query('SELECT * FROM sg_messages WHERE id=$1', [pay.addon_message_id]);
    const meta = m.metadata_json;
    const modules = [
      ...quote.modules_json,
      {
        id: `addon-${m.id.slice(0, 8)}`,
        name: meta.title,
        description: meta.description || '',
        price_cents: pay.amount_cents,
        optional: false,
        included: true,
        addon: true,
      },
    ];
    const hash = scopeHash(quote.brief_json, modules);
    await c.query(
      `UPDATE sg_quotes SET modules_json=$2, version=version+1, updated_at=now() WHERE id=$1`,
      [quote.id, JSON.stringify(modules)],
    );
    await c.query(
      `UPDATE sg_messages SET metadata_json = metadata_json || '{"status":"paid"}'::jsonb WHERE id=$1`,
      [m.id],
    );
    await c.query(
      `UPDATE sg_orders SET scope_hash=$2, total_cents=$3, updated_at=now() WHERE id=$1`,
      [pay.order_id, hash, totalOf(modules)],
    );
    return { pay, hash, addonMessageId: m.id, note: `➕ Add-on "${meta.title}" paid ($${(pay.amount_cents / 100).toFixed(2)}). Scope updated (${hash.slice(0, 12)}…).` };
  });

  if (!result) return { settled: true, alreadySettled: true };
  await insertMessage({ orderId: result.pay.order_id, senderRole: 'system', content: result.note, metadata: { payment: result.pay.kind } });
  if (result.addonMessageId) {
    const m = await one('SELECT metadata_json FROM sg_messages WHERE id=$1', [result.addonMessageId]);
    emit.toOrder(result.pay.order_id, 'chat:updated', { id: result.addonMessageId, metadata: m.metadata_json });
  }
  const order = await broadcastOrder(result.pay.order_id);
  if (result.pay.kind === 'initial') emit.toDevs('order:paid', order);
  compileSoon(result.pay.order_id); // turn the locked scope into acceptance criteria for the escrow audits
  return { settled: true, order };
}
