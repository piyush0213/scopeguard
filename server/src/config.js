import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';

// Secrets can live outside the repo: set KEYS_DIR to a folder that holds one file per
// variable (e.g. KEYS_DIR/GEMINI_API_KEY). Real env vars always win.
const SECRET_NAMES = [
  'DATABASE_URL',
  'OPENROUTER_API_KEY',
  'GEMINI_API_KEY',
  'STRIPE_SECRET_KEY',
  'STRIPE_WEBHOOK_SECRET',
  'GITHUB_WEBHOOK_SECRET',
  'GITHUB_TOKEN',
  'JWT_SECRET',
];
if (process.env.KEYS_DIR) {
  for (const name of SECRET_NAMES) {
    if (process.env[name]) continue;
    const file = path.join(process.env.KEYS_DIR, name);
    if (fs.existsSync(file)) process.env[name] = fs.readFileSync(file, 'utf8').trim();
  }
}

function required(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var ${name}`);
  return v;
}

export const config = {
  port: Number(process.env.PORT || 4000),
  appUrl: (process.env.APP_URL || 'http://localhost:5173').replace(/\/$/, ''),
  databaseUrl: required('DATABASE_URL'),
  jwtSecret: required('JWT_SECRET'),
  openrouterKey: process.env.OPENROUTER_API_KEY || '',
  // Comma-separated; tried in order. Free Nemotron 3 Ultra first, paid Haiku as a rate-limit backup.
  openrouterModels: (process.env.OPENROUTER_MODEL || 'nvidia/nemotron-3-ultra-550b-a55b:free,anthropic/claude-haiku-5.5')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  // Reasoning models spend tokens thinking before the JSON, so leave headroom.
  openrouterMaxTokens: Number(process.env.OPENROUTER_MAX_TOKENS || 6000),
  geminiKey: process.env.GEMINI_API_KEY || '',
  geminiModel: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
  stripeKey: process.env.STRIPE_SECRET_KEY || '',
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',
  githubWebhookSecret: process.env.GITHUB_WEBHOOK_SECRET || '',
  githubRepo: process.env.GITHUB_REPO || '',
  // Optional: falls back to the local GitHub CLI login (gh auth token).
  githubToken: process.env.GITHUB_TOKEN || '',
  // Public base URL of this API (e.g. ngrok). When set, connecting a repo auto-registers a webhook.
  publicUrl: (process.env.PUBLIC_URL || '').replace(/\/$/, ''),
  githubPollMs: Number(process.env.GITHUB_POLL_MS || 0),
  // Stage 7: auto-complete delivered orders after this many hours (0 disables). Use e.g. 0.05 (3 min) for a demo.
  autoAcceptHours: Number(process.env.AUTO_ACCEPT_HOURS ?? 72),
  currency: process.env.CURRENCY || 'usd',
};
