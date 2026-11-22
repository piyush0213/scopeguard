-- ScopeGuard schema (idempotent). All tables prefixed sg_ so it can share a database.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS sg_users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('client','dev')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS sg_order_seq START 1042;

CREATE TABLE IF NOT EXISTS sg_orders (
  id            TEXT PRIMARY KEY DEFAULT ('CD-' || nextval('sg_order_seq')),
  client_id     UUID NOT NULL REFERENCES sg_users(id),
  dev_id        UUID REFERENCES sg_users(id),
  title         TEXT NOT NULL,
  type          TEXT NOT NULL CHECK (type IN ('menu','custom')),
  -- pre-pay: scoping | ai_draft | negotiating | awaiting_payment
  -- post-pay: paid | accepted | cooking | quality_check | out_for_delivery | taste_test | delivered | completed
  status        TEXT NOT NULL,
  stage         INT  NOT NULL DEFAULT -1,
  ci_failed     BOOLEAN NOT NULL DEFAULT false,
  branch_name   TEXT UNIQUE,
  preview_url   TEXT,
  pr_url        TEXT,
  scope_hash    TEXT,
  total_cents   INT NOT NULL DEFAULT 0,
  paid          BOOLEAN NOT NULL DEFAULT false,
  scoping_json  JSONB NOT NULL DEFAULT '{}'::jsonb,
  timeline_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sg_quotes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     TEXT NOT NULL REFERENCES sg_orders(id) ON DELETE CASCADE,
  version      INT NOT NULL DEFAULT 1,
  brief_json   JSONB NOT NULL DEFAULT '{}'::jsonb,
  modules_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  status       TEXT NOT NULL CHECK (status IN ('ai_draft','negotiating','locked')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS sg_quotes_order_uq ON sg_quotes(order_id);

CREATE TABLE IF NOT EXISTS sg_messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      TEXT NOT NULL REFERENCES sg_orders(id) ON DELETE CASCADE,
  sender_id     UUID REFERENCES sg_users(id),
  sender_role   TEXT NOT NULL CHECK (sender_role IN ('client','dev','system')),
  type          TEXT NOT NULL CHECK (type IN ('text','quote_revision','scope_addon')),
  content       TEXT NOT NULL,
  metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  scope_flagged BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sg_messages_order_idx ON sg_messages(order_id, created_at);

CREATE TABLE IF NOT EXISTS sg_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     TEXT REFERENCES sg_orders(id) ON DELETE CASCADE,
  delivery_id  TEXT NOT NULL UNIQUE,
  event_type   TEXT NOT NULL,
  payload_json JSONB NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sg_payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          TEXT NOT NULL REFERENCES sg_orders(id) ON DELETE CASCADE,
  stripe_session_id TEXT UNIQUE,
  amount_cents      INT NOT NULL,
  kind              TEXT NOT NULL CHECK (kind IN ('initial','addon')),
  addon_message_id  UUID,
  snapshot_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
  status           TEXT NOT NULL CHECK (status IN ('pending','paid')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sg_menu_items (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT NOT NULL,
  price_cents INT NOT NULL,
  eta_days    INT NOT NULL,
  emoji       TEXT NOT NULL DEFAULT '🧩'
);

-- Per-order GitHub repo for the live tracker.
ALTER TABLE sg_orders ADD COLUMN IF NOT EXISTS repo_full_name TEXT;
ALTER TABLE sg_orders ADD COLUMN IF NOT EXISTS repo_hook_id BIGINT;
ALTER TABLE sg_orders ADD COLUMN IF NOT EXISTS repo_sync_json JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Proof-of-Delivery: acceptance criteria, latest code audit, per-module escrow ledger.
ALTER TABLE sg_orders ADD COLUMN IF NOT EXISTS proof_json JSONB NOT NULL DEFAULT '{}'::jsonb;
