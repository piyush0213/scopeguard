import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

export const db = {
  query: (text, params) => pool.query(text, params),
  one: async (text, params) => (await pool.query(text, params)).rows[0] || null,
};

export async function migrate() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id               SERIAL PRIMARY KEY,
      email            TEXT UNIQUE NOT NULL,
      name             TEXT NOT NULL DEFAULT '',
      password_hash    TEXT,
      google_id        TEXT UNIQUE,
      email_verified   BOOLEAN NOT NULL DEFAULT false,
      verify_token_hash TEXT,
      reset_token_hash TEXT,
      reset_expires    TIMESTAMPTZ,
      created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
    )`);
}
