// Proof-of-Delivery smoke test: creates a throwaway paid order pointed at a public repo, runs a real
// audit through the API, prints the verdicts, then deletes the order. Usage: node scripts/proof-test.mjs owner/repo
import { one, query, pool } from '../src/db.js';

const API = 'http://localhost:4000';
const repo = process.argv[2] || 'vercel/nextjs-subscription-payments';
const keep = process.argv.includes('--keep');

async function login(email) {
  const r = await fetch(`${API}/api/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'demo1234' }) });
  const d = await r.json();
  if (!d.token) throw new Error(`login ${email}: ${JSON.stringify(d)}`);
  return d;
}
const call = async (token, path, opts = {}) => {
  const r = await fetch(`${API}${path}`, { ...opts, headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' } });
  const d = await r.json();
  if (!r.ok) throw new Error(`${path}: ${d.error}`);
  return d;
};

const client = await login('client@demo.dev');
const dev = await login('dev@demo.dev');
const repoInfo = await (await fetch(`https://api.github.com/repos/${repo}`)).json();
const modules = process.argv.includes('--release') ? [
  { id: 'menu-auth-module', name: 'Auth Module', description: 'Email/password sign-up and sign-in, plus GitHub OAuth sign-in.', price_cents: 25000, optional: false, included: true, menu: true },
  { id: 'm1', name: 'Pricing page', description: 'Page that lists the subscription products and prices from the database.', price_cents: 30000, optional: false, included: true },
] : [
  { id: 'menu-auth-module', name: 'Auth Module', description: 'Email/password + OAuth sign-in, protected routes and session handling.', price_cents: 25000, optional: false, included: true, menu: true },
  { id: 'menu-stripe-payments', name: 'Stripe Payments', description: 'Subscriptions checkout with Stripe webhooks that keep the database in sync.', price_cents: 40000, optional: false, included: true, menu: true },
  { id: 'm1', name: 'Mobile app', description: 'Native iOS app with push notifications.', price_cents: 120000, optional: false, included: true },
];
const brief = { title: 'SaaS starter', summary: 'Subscription SaaS with auth and billing', in_scope: modules.map((m) => m.name) };
const o = await one(
  `INSERT INTO sg_orders (id, client_id, dev_id, title, type, status, stage, paid, total_cents, branch_name, repo_full_name, repo_sync_json, scope_hash)
   VALUES ('PT-' || floor(random()*1e6)::text, (SELECT id FROM sg_users WHERE email='client@demo.dev'), (SELECT id FROM sg_users WHERE email='dev@demo.dev'),
           'Proof test', 'custom', 'cooking', 2, true, 185000, 'order/PROOF-TEST-' || floor(random()*1e6)::text, $1, $2, 'test') RETURNING id`,
  [repo, { defaultBranch: repoInfo.default_branch, mode: 'polling' }],
);
await query(`INSERT INTO sg_quotes (order_id, brief_json, modules_json, status) VALUES ($1,$2,$3,'locked')`, [o.id, brief, JSON.stringify(modules)]);
console.log(`order ${o.id} -> ${repo}@${repoInfo.default_branch}`);

try {
  // Client is allowed to trigger it too.
  console.log('audit:', await call(client.token, `/api/orders/${o.id}/proof/audit`, { method: 'POST' }));
  const t0 = Date.now();
  let order;
  let last = '';
  for (;;) {
    await new Promise((r) => setTimeout(r, 2000));
    ({ order } = await call(client.token, `/api/orders/${o.id}`));
    const p = order.proof;
    const line = `${p.status} ${p.progress || ''} ${p.error || ''}`;
    if (line !== last) console.log(`  [${Math.round((Date.now() - t0) / 1000)}s] ${line}`);
    last = line;
    if (p.audit || p.status === 'error') break;
    if (Date.now() - t0 > 300_000) throw new Error('timeout');
  }
  const p = order.proof;
  if (p.status === 'error') throw new Error(p.error);
  console.log(`\nfiles read ${p.audit.filesRead}/${p.audit.filesInRepo} · ${JSON.stringify(p.audit.counts)} · ${p.audit.summary}\n`);
  for (const m of modules) {
    console.log(`${m.name}  escrow=${p.escrow[m.id]?.state}`);
    for (const c of p.criteria[m.id]) {
      const r = p.audit.results[c.id];
      console.log(`   ${r.status.padEnd(7)} ${c.text}\n           ${r.evidence ? `${r.evidence.file}:${r.evidence.lineStart}-${r.evidence.lineEnd}` : '-'} · ${r.note}`);
    }
  }
  console.log('\nproof score:', await call(client.token, `/api/proof-score/${order.devId}`));
} finally {
  if (!keep) await query('DELETE FROM sg_orders WHERE id=$1', [o.id]);
  await pool.end();
}
