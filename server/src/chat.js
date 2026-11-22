import { one, query } from './db.js';
import { HttpError } from './auth.js';
import { checkScope } from './ai.js';
import { emit } from './realtime.js';
import { loadOrderFor, insertMessage } from './services.js';

/** Persist a chat message, broadcast it, and (for paid orders) run ScopeGuard in the background. */
export async function postChat(user, orderId, content) {
  const text = String(content || '').trim();
  if (!text) throw new HttpError(400, 'Message is empty');
  if (text.length > 4000) throw new HttpError(400, 'Message too long');
  const order = await loadOrderFor(user, orderId);
  const msg = await insertMessage({ orderId, senderId: user.id, senderRole: user.role, content: text });

  const scopeLocked = order.paid && order.stage >= 0 && order.stage <= 5 && order.quote;
  if (user.role === 'client' && scopeLocked) {
    runScopeGuard(order, msg).catch((e) => console.error('[scopeguard]', e.message));
  }
  return msg;
}

async function runScopeGuard(order, msg) {
  emit.toOrderDevs(order.id, 'scope:checking', { messageId: msg.id });
  const verdict = await checkScope({ brief: order.quote.brief, modules: order.quote.modules, message: msg.content });
  const scopeCheck = {
    outOfScope: !!verdict.out_of_scope,
    confidence: verdict.confidence ?? null,
    reason: verdict.reason,
    suggestion: verdict.out_of_scope
      ? {
          title: verdict.suggested_addon_title || 'Scope add-on',
          description: verdict.suggested_addon_description || '',
          priceCents: Math.max(0, Math.round(Number(verdict.suggested_price_usd) || 0)) * 100,
        }
      : null,
    checkedAt: new Date().toISOString(),
  };
  await query(
    `UPDATE sg_messages SET scope_flagged=$2, metadata_json = metadata_json || jsonb_build_object('scopeCheck', $3::jsonb)
     WHERE id=$1`,
    [msg.id, scopeCheck.outOfScope, JSON.stringify(scopeCheck)],
  );
  // Dev-only channel: the client never sees the flag.
  emit.toOrderDevs(order.id, 'scope:flagged', { messageId: msg.id, ...scopeCheck });
  if (scopeCheck.outOfScope) emit.toDevs('scope:alert', { orderId: order.id, messageId: msg.id, reason: scopeCheck.reason });
}

export async function canJoin(user, orderId) {
  const o = await one('SELECT client_id FROM sg_orders WHERE id=$1', [orderId]);
  if (!o) return false;
  return user.role === 'dev' || o.client_id === user.id;
}
