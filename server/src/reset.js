// Clears all orders for a clean pitch. Keeps users, menu, and recorded GitHub payloads (for Ctrl+K replay).
import { pool, migrate } from './db.js';
import { seed } from './seed.js';

await migrate();
await pool.query('UPDATE sg_events SET order_id = NULL');
await pool.query('DELETE FROM sg_payments');
await pool.query('DELETE FROM sg_messages');
await pool.query('DELETE FROM sg_quotes');
await pool.query('DELETE FROM sg_orders');
await pool.query('ALTER SEQUENCE sg_order_seq RESTART WITH 1042');
await seed();
console.log('Demo data reset. Next order will be CD-1042.');
await pool.end();
