import crypto from 'node:crypto';
import { one, many, query } from './db.js';
import { HttpError } from './auth.js';
import { emit } from './realtime.js';
import { config } from './config.js';

export const STAGES = [
  { key: 'paid', label: 'Paid & Queued' },
  { key: 'accepted', label: 'Order Accepted' },
  { key: 'cooking', label: 'Cooking' },
  { key: 'quality_check', label: 'Quality Check' },
  { key: 'out_for_delivery', label: 'Out for Delivery' },
  { key: 'taste_test', label: 'Taste Test' },
  { key: 'delivered', label: 'Delivered' },
  { key: 'completed', label: 'Completed' },
];

export const totalOf = (modules) =>
  modules.filter((m) => m.included || !m.optional).reduce((s, m) => s + (m.price_cents || 0), 0);

export function scopeHash(brief, modules) {
  const canonical = JSON.stringify({
    brief,
    modules: modules
      .filter((m) => m.included || !m.optional)
      .map((m) => ({ id: m.id, name: m.name, description: m.description, price_cents: m.price_cents }))
      .sort((a, b) => a.id.localeCompare(b.id)),
  });
  return crypto.createHash('sha256').update(canonical).digest('hex');
}

const ORDER_SELECT = `
  SELECT o.*, c.name AS client_name, d.name AS dev_name,
         q.id AS quote_id, q.version AS quote_version, q.status AS quote_status,
         q.brief_json, q.modules_json
  FROM sg_orders o
  JOIN sg_users c ON c.id = o.client_id
  LEFT JOIN sg_users d ON d.id = o.dev_id
  LEFT JOIN sg_quotes q ON q.order_id = o.id`;

function shape(r) {
  if (!r) return null;
  return {
    id: r.id,
    title: r.title,
    type: r.type,
    status: r.status,
    stage: r.stage,
    ciFailed: r.ci_failed,
    branchName: r.branch_name,
    previewUrl: r.preview_url,
    prUrl: r.pr_url,
    repoFullName: r.repo_full_name,
    repoHookId: r.repo_hook_id,
    repoSync: r.repo_sync_json,
    proof: r.proof_json || {},
    autoAcceptAt:
      r.stage === 6 && r.timeline_json?.[6] && config.autoAcceptHours > 0
        ? new Date(new Date(r.timeline_json[6]).getTime() + config.autoAcceptHours * 3600e3).toISOString()
        : null,
    scopeHash: r.scope_hash,
    totalCents: r.total_cents,
    paid: r.paid,
    scoping: r.scoping_json,
    timeline: r.timeline_json,
    clientId: r.client_id,
    clientName: r.client_name,
    devId: r.dev_id,
    devName: r.dev_name,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
    quote: r.quote_id
      ? { id: r.quote_id, version: r.quote_version, status: r.quote_status, brief: r.brief_json, modules: r.modules_json }
      : null,
  };
}

export async function getOrder(id) {
  return shape(await one(`${ORDER_SELECT} WHERE o.id=$1`, [id]));
}
export async function listOrders(where = '', params = []) {
  return (await many(`${ORDER_SELECT} ${where} ORDER BY o.updated_at DESC`, params)).map(shape);
}

export async function loadOrderFor(user, id) {
  const order = await getOrder(id);
  if (!order) throw new HttpError(404, 'Order not found');
  if (user.role === 'client' && order.clientId !== user.id) throw new HttpError(403, 'Not your order');
  return order;
}

/** Push the latest order snapshot to everyone who should see it. */
export async function broadcastOrder(id) {
  const order = await getOrder(id);
  if (!order) return null;
  emit.toRooms([`order:${id}`, `user:${order.clientId}`, 'devs'], 'order:updated', order);
  return order;
}

export async function insertMessage({ orderId, senderId = null, senderRole, type = 'text', content, metadata = {} }) {
  const row = await one(
    `INSERT INTO sg_messages (order_id,sender_id,sender_role,type,content,metadata_json)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [orderId, senderId, senderRole, type, content, metadata],
  );
  const msg = await shapeMessage(row);
  emit.toOrder(orderId, 'chat:message', msg);
  return msg;
}

export async function shapeMessage(row) {
  const sender = row.sender_id ? await one('SELECT name FROM sg_users WHERE id=$1', [row.sender_id]) : null;
  return {
    id: row.id,
    orderId: row.order_id,
    senderId: row.sender_id,
    senderName: sender?.name || 'ScopeGuard',
    senderRole: row.sender_role,
    type: row.type,
    content: row.content,
    metadata: row.metadata_json,
    scopeFlagged: row.scope_flagged,
    createdAt: row.created_at,
  };
}

export async function listMessages(orderId, role) {
  const rows = await many(
    `SELECT m.*, u.name AS sender_name FROM sg_messages m LEFT JOIN sg_users u ON u.id=m.sender_id
     WHERE m.order_id=$1 ORDER BY m.created_at ASC`,
    [orderId],
  );
  return rows.map((row) => ({
    id: row.id,
    orderId: row.order_id,
    senderId: row.sender_id,
    senderName: row.sender_name || 'ScopeGuard',
    senderRole: row.sender_role,
    type: row.type,
    content: row.content,
    // Scope flags + AI reasoning are dev-only.
    metadata: role === 'dev' ? row.metadata_json : stripDevOnly(row.metadata_json),
    scopeFlagged: role === 'dev' ? row.scope_flagged : false,
    createdAt: row.created_at,
  }));
}
function stripDevOnly(meta = {}) {
  const { scopeCheck, ...rest } = meta;
  return rest;
}

/**
 * Move an order through the build state machine. Forward-only unless `force` (used for CI failure reverts).
 * Returns the updated order or null if nothing changed.
 */
export async function setStage(orderId, target, { force = false, set = {}, note, announce = false } = {}) {
  const current = await one('SELECT stage, timeline_json FROM sg_orders WHERE id=$1', [orderId]);
  if (!current) return null;
  const moving = force ? target !== current.stage : target > current.stage;
  const timeline = { ...current.timeline_json };
  if (moving) {
    timeline[target] = new Date().toISOString();
    if (target < current.stage) for (const k of Object.keys(timeline)) if (Number(k) > target) delete timeline[k];
  }
  const cols = Object.keys(set);
  if (!moving && cols.length === 0) return null;
  const params = [orderId, moving ? target : current.stage, moving ? STAGES[target].key : null, timeline];
  const extra = cols.map((c, i) => `${c}=$${i + 5}`).join(', ');
  await query(
    `UPDATE sg_orders SET stage=$2, status=COALESCE($3,status), timeline_json=$4, updated_at=now()
     ${extra ? ', ' + extra : ''} WHERE id=$1`,
    [...params, ...cols.map((c) => set[c])],
  );
  if (moving || announce) {
    await insertMessage({
      orderId,
      senderRole: 'system',
      content: note || `Order moved to ${STAGES[target].label}.`,
      metadata: { stage: target },
    });
  }
  return broadcastOrder(orderId);
}
