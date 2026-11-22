import pg from 'pg';
import fs from 'node:fs';
import { config } from './config.js';

// Tolerates passwords with unencoded '@' or ':' (common in copied Supabase URLs).
function parseUrl(raw) {
  const m = raw.match(/^postgres(?:ql)?:\/\/(.*)$/);
  if (!m) return { connectionString: raw };
  const rest = m[1];
  const at = rest.lastIndexOf('@');
  if (at === -1) return { connectionString: raw };
  const cred = rest.slice(0, at);
  const hostPart = rest.slice(at + 1);
  const colon = cred.indexOf(':');
  const user = decodeURIComponent(colon === -1 ? cred : cred.slice(0, colon));
  const password = colon === -1 ? undefined : safeDecode(cred.slice(colon + 1));
  const [hostPort, dbAndQuery = 'postgres'] = splitOnce(hostPart, '/');
  const [database] = dbAndQuery.split('?');
  const [host, port] = splitOnce(hostPort, ':');
  return { user, password, host, port: Number(port || 5432), database: database || 'postgres' };
}
function splitOnce(s, ch) {
  const i = s.indexOf(ch);
  return i === -1 ? [s, undefined] : [s.slice(0, i), s.slice(i + 1)];
}
function safeDecode(s) {
  try { return decodeURIComponent(s); } catch { return s; }
}

const conn = parseUrl(config.databaseUrl);
const isLocal = ['localhost', '127.0.0.1'].includes(conn.host);

export const pool = new pg.Pool({
  ...conn,
  ssl: isLocal ? false : { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30_000,
});
pool.on('error', (err) => console.error('[db] idle client error', err.message));

export const query = (text, params) => pool.query(text, params);
export async function one(text, params) {
  const { rows } = await pool.query(text, params);
  return rows[0] || null;
}
export async function many(text, params) {
  const { rows } = await pool.query(text, params);
  return rows;
}
export async function tx(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query('COMMIT');
    return out;
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}

export async function migrate() {
  const sql = fs.readFileSync(new URL('./schema.sql', import.meta.url), 'utf8');
  await pool.query(sql);
}
