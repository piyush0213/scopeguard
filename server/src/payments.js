import Stripe from 'stripe';
import { config } from './config.js';
import { tx, one } from './db.js';
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
 * Create an immediate-capture Stripe Checkout Session and a pending payment row.
 * lineItems: [{ name, description, amountCents }]
 */
export async function createCheckout({ order, lineItems, kind, addonMessageId = null, snapshot = {}, customerEmail }) {
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
    success_url: `${config.appUrl}/client/orders/${order.id}?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${config.appUrl}/client/orders/${order.id}?canceled=1`,
  });
  await one(
    `INSERT INTO sg_payments (order_id,stripe_session_id,amount_cents,kind,addon_message_id,snapshot_json,status)
     VALUES ($1,$2,$3,$4,$5,$6,'pending') RETURNING id`,
    [order.id, session.id, amount, kind, addonMessageId, snapshot],
  );
  return session;
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
