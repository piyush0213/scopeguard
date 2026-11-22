// Proof-of-Delivery: the paid scope is compiled into acceptance criteria, every new commit is audited by AI
// against the real source code, and each module's escrow is released only when all its criteria are proven
// with a verified file + line citation. The AI never gets the final word: citations are re-checked against
// the fetched files and the evidence shown to the client is the real code, not model output.
import crypto from 'node:crypto';
import { many, query } from './db.js';
import { HttpError } from './auth.js';
import { gh } from './github-sync.js';
import { compileCriteria, auditCode } from './ai.js';
import { getOrder, insertMessage, broadcastOrder } from './services.js';

const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');
const lockedModules = (order) => (order.quote?.modules || []).filter((m) => m.included || !m.optional);
const usd = (c) => `$${(c / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })}`;

async function saveProof(orderId, patch, { broadcast = true } = {}) {
  await query(`UPDATE sg_orders SET proof_json = proof_json || $2::jsonb, updated_at=now() WHERE id=$1`, [orderId, JSON.stringify(patch)]);
  if (broadcast) await broadcastOrder(orderId);
}

/* ------------------------------------------------------------------ 1. Executable contract */
export async function ensureCriteria(order) {
  const mods = lockedModules(order);
  const have = order.proof?.criteria || {};
  const missing = mods.filter((m) => !have[m.id]?.length);
  if (!missing.length) return have;

  await saveProof(order.id, { status: 'compiling', progress: `Compiling acceptance criteria for ${missing.length} module${missing.length > 1 ? 's' : ''}…` });
  let compiled = [];
  try {
    compiled = await compileCriteria({ brief: order.quote.brief, modules: missing });
  } catch (e) {
    console.warn(`[proof] ${order.id} criteria compile failed, using module descriptions: ${e.message}`);
  }
  const criteria = { ...have };
  for (const m of missing) {
    const got =
      compiled.find((x) => x.module_id === m.id) ||
      compiled.find((x) => String(x.module_id).toLowerCase() === m.name.toLowerCase());
    const list = got?.criteria?.length ? got.criteria : [{ text: `${m.name}: ${m.description || 'implemented as described'}`, look_for: m.name }];
    criteria[m.id] = list.slice(0, 4).map((c, i) => ({
      id: `${m.id}.c${i + 1}`,
      text: String(c.text || '').trim(),
      look_for: String(c.look_for || '').trim(),
    }));
  }
  const ordered = Object.fromEntries(Object.keys(criteria).sort().map((k) => [k, criteria[k]]));
  await saveProof(order.id, {
    criteria,
    criteriaHash: sha256(JSON.stringify(ordered)),
    compiledAt: new Date().toISOString(),
    status: 'idle',
    progress: null,
  });
  return criteria;
}

export function compileSoon(orderId) {
  setTimeout(async () => {
    try {
      const order = await getOrder(orderId);
      if (order?.paid) await ensureCriteria(order);
    } catch (e) {
      console.warn(`[proof] compile ${orderId}: ${e.message}`);
    }
  }, 200);
}

/* ------------------------------------------------------------------ 2. Code snapshot from GitHub */
const SKIP_DIR = /(^|\/)(node_modules|dist|build|out|coverage|vendor|\.next|\.nuxt|\.git|__pycache__|\.venv|venv|target|bin|obj)\//i;
const SKIP_FILE = /(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|Gemfile\.lock|\.min\.(js|css)|\.map|\.snap)$/i;
const CODE = /\.(jsx?|tsx?|mjs|cjs|py|go|rb|java|kt|swift|php|cs|rs|vue|svelte|astro|html|css|scss|sql|prisma|graphql|ya?ml|toml|json|dart|ex|exs|sh)$/i;
const MAX_FILES = 70;
const MAX_FILE_CHARS = 9000;
const MAX_TOTAL_CHARS = 160_000;
const blobCache = new Map(); // blob sha -> text (blobs are immutable)
const STOP = new Set(['with', 'that', 'this', 'from', 'when', 'into', 'user', 'users', 'must', 'each', 'page', 'have', 'shows', 'data', 'code', 'file', 'returns', 'should', 'using', 'which', 'their', 'there', 'where', 'only', 'more', 'also']);
const keywordsOf = (criteria) => [
  ...new Set(
    criteria
      .flatMap((c) => `${c.text} ${c.look_for}`.toLowerCase().split(/[^a-z0-9]+/))
      .filter((w) => w.length >= 4 && !STOP.has(w))
      .map((w) => w.replace(/(ing|es|s)$/, '')),
  ),
];

async function snapshot(repo, sha, base, keywords, onProgress) {
  const tree = await gh(`/repos/${repo}/git/trees/${sha}?recursive=1`);
  const blobs = (tree.tree || []).filter(
    (t) => t.type === 'blob' && CODE.test(t.path) && !SKIP_DIR.test(t.path) && !SKIP_FILE.test(t.path) && t.size > 0 && t.size < 250_000,
  );
  const changed = new Set();
  if (base) {
    try {
      const cmp = await gh(`/repos/${repo}/compare/${encodeURIComponent(base)}...${sha}`);
      for (const f of cmp.files || []) changed.add(f.filename);
    } catch {
      /* branch == base or unrelated histories: audit the whole tree */
    }
  }
  // Files the developer changed come first, then files whose path matches the contract's vocabulary
  // (webhook, checkout, auth…), then source over config, shallow over deep, small over large.
  const hits = (p) => keywords.filter((k) => p.toLowerCase().includes(k)).length;
  const rank = (f) =>
    (changed.has(f.path) ? 0 : 100) - Math.min(hits(f.path), 3) * 30 + (/\.(json|ya?ml|toml)$/i.test(f.path) ? 50 : 0) + f.path.split('/').length;
  blobs.sort((a, b) => rank(a) - rank(b) || a.size - b.size);

  const files = [];
  let total = 0;
  for (const b of blobs) {
    if (files.length >= MAX_FILES || total >= MAX_TOTAL_CHARS) break;
    let text = blobCache.get(b.sha);
    if (text === undefined) {
      const blob = await gh(`/repos/${repo}/git/blobs/${b.sha}`);
      text = Buffer.from(blob.content || '', blob.encoding === 'base64' ? 'base64' : 'utf8').toString('utf8');
      blobCache.set(b.sha, text);
    }
    if (text.includes('\u0000')) continue; // binary
    const lines = text.replace(/\r\n/g, '\n').split('\n');
    let shown = 0;
    let chars = 0;
    while (shown < lines.length && chars + lines[shown].length < MAX_FILE_CHARS && total + chars < MAX_TOTAL_CHARS) chars += lines[shown++].length + 6;
    if (!shown) continue;
    files.push({ path: b.path, lines, shown, changed: changed.has(b.path) });
    total += chars;
    if (files.length % 8 === 0) onProgress?.(`Reading source… ${files.length} files`);
  }
  return { files, treeCount: blobs.length, changedCount: changed.size };
}

const renderCorpus = (files) =>
  files
    .map((f) => `=== ${f.path} ===\n${f.lines.slice(0, f.shown).map((l, i) => `${i + 1}| ${l}`).join('\n')}${f.shown < f.lines.length ? `\n… (${f.lines.length - f.shown} more lines)` : ''}`)
    .join('\n\n');

/* ------------------------------------------------------------------ 3. Audit + escrow */
const running = new Set();
const pending = new Map();

export function queueAudit(orderId, sha, { force = false } = {}) {
  if (running.has(orderId)) {
    if (force || pending.get(orderId)?.sha !== sha) pending.set(orderId, { sha, force });
    return;
  }
  runAudit(orderId, sha, force).catch((e) => console.warn(`[proof] ${orderId}: ${e.message}`));
}

async function runAudit(orderId, sha, force) {
  const order = await getOrder(orderId);
  if (!order?.paid || !order.repoFullName || !sha) return;
  if (!force && (order.proof?.audit?.sha === sha || order.proof?.failedSha === sha)) return;
  running.add(orderId);
  const repo = order.repoFullName;
  try {
    const criteria = await ensureCriteria(order);
    const mods = lockedModules(order);
    const list = mods.flatMap((m) => criteria[m.id] || []);

    await saveProof(orderId, { status: 'auditing', progress: `Fetching commit ${sha.slice(0, 7)} from ${repo}…`, error: null });
    const progress = (text) => saveProof(orderId, { progress: text }).catch(() => {});
    const base = order.repoSync?.defaultBranch && order.repoSync.defaultBranch !== order.branchName ? order.repoSync.defaultBranch : null;
    const snap = await snapshot(repo, sha, base, keywordsOf(list), progress);
    if (!snap.files.length) throw new Error('No source files found on the branch yet — push some code first.');

    await progress(`AI auditor is checking ${list.length} criteria against ${snap.files.length} files…`);
    const ai = await auditCode({ criteria: list, corpus: renderCorpus(snap.files), fileList: snap.files.map((f) => f.path) });

    // Verify every citation against the real files; anything we can't confirm is not proof.
    const results = {};
    for (const c of list) {
      const r = (ai.results || []).find((x) => x.id === c.id) || {};
      let status = ['proven', 'partial', 'missing'].includes(String(r.status).toLowerCase()) ? String(r.status).toLowerCase() : 'missing';
      let note = String(r.note || '').trim();
      let evidence = null;
      if (status !== 'missing') {
        const cited = String(r.file || '').replace(/^\.?\//, '');
        const file = snap.files.find((f) => f.path === cited) || snap.files.find((f) => cited && (f.path.endsWith(`/${cited}`) || cited.endsWith(`/${f.path}`)));
        const start = Math.max(1, Math.min(Number(r.line_start) || 1, file?.lines.length || 1));
        const end = Math.min(Math.max(start, Number(r.line_end) || start), start + 60, file?.lines.length || start);
        const snippet = file ? file.lines.slice(start - 1, Math.min(end, start + 13)).join('\n') : '';
        if (!file || !snippet.trim()) {
          status = 'missing';
          note = `${note} The auditor's citation could not be found in the repo, so it doesn't count.`.trim();
        } else {
          evidence = { file: file.path, lineStart: start, lineEnd: end, snippet, url: `https://github.com/${repo}/blob/${sha}/${file.path}#L${start}-L${end}` };
        }
      }
      results[c.id] = { status, note, evidence };
    }

    // Escrow: a module's money is released once ALL its criteria are proven (and CI isn't red). Releases are final.
    const prev = order.proof?.escrow || {};
    const escrow = {};
    const released = [];
    for (const m of mods) {
      const cs = criteria[m.id] || [];
      if (prev[m.id]?.state === 'released') {
        escrow[m.id] = prev[m.id];
        continue;
      }
      const proven = cs.length > 0 && cs.every((c) => results[c.id]?.status === 'proven');
      if (proven && !order.ciFailed) {
        escrow[m.id] = { state: 'released', amountCents: m.price_cents, releasedAt: new Date().toISOString(), sha, txId: `esc_${crypto.randomBytes(6).toString('hex')}` };
        released.push(m);
      } else {
        escrow[m.id] = { state: 'held', amountCents: m.price_cents, blockedByCi: proven && order.ciFailed };
      }
    }

    const counts = { proven: 0, partial: 0, missing: 0 };
    for (const r of Object.values(results)) counts[r.status]++;
    const audit = {
      sha,
      at: new Date().toISOString(),
      // Some models leak JSON into the string; keep only the prose.
      summary: String(ai.summary || '').split(/['"]\s*,\s*['"]?results/)[0].trim(),
      filesRead: snap.files.length,
      filesInRepo: snap.treeCount,
      changedFiles: snap.changedCount,
      fileList: snap.files.map((f) => f.path),
      results,
      counts,
      total: list.length,
    };
    const history = [...(order.proof?.history || []), { sha, at: audit.at, ...counts, total: list.length }].slice(-12);
    await saveProof(orderId, { status: 'idle', progress: null, error: null, failedSha: null, audit, escrow, history }, { broadcast: false });

    await insertMessage({
      orderId,
      senderRole: 'system',
      content: `🔎 Proof audit of commit ${sha.slice(0, 7)}: ${counts.proven}/${list.length} acceptance criteria proven in code${counts.partial ? `, ${counts.partial} in progress` : ''}. ${audit.summary}`,
      metadata: { proofAudit: true, sha },
    });
    for (const m of released) {
      const first = (criteria[m.id] || []).map((c) => results[c.id]?.evidence).find(Boolean);
      await insertMessage({
        orderId,
        senderRole: 'system',
        content: `🔓 Escrow released: ${usd(m.price_cents)} for "${m.name}" — all ${criteria[m.id].length} criteria proven${first ? ` (e.g. ${first.file}:${first.lineStart})` : ''}.`,
        metadata: { escrowRelease: true, moduleId: m.id, amountCents: m.price_cents },
      });
    }
    await broadcastOrder(orderId);
  } catch (e) {
    const msg = e.status === 429 ? 'GitHub rate limit reached — the audit will retry on the next commit.' : e.message;
    console.warn(`[proof] audit ${orderId} failed: ${msg}`);
    await saveProof(orderId, { status: 'error', progress: null, error: msg, failedSha: sha }).catch(() => {});
  } finally {
    running.delete(orderId);
    const next = pending.get(orderId);
    if (next) {
      pending.delete(orderId);
      queueAudit(orderId, next.sha, next);
    }
  }
}

/** Manual "audit now": resolves the branch head (or the default branch once the branch is merged & deleted). */
export async function auditNow(order) {
  if (!order.paid) throw new HttpError(409, 'Audits start after the order is paid');
  if (!order.repoFullName) throw new HttpError(409, 'Connect a GitHub repo to this order first');
  if (running.has(order.id)) return { queued: true };
  const enc = encodeURIComponent;
  let branch = await gh(`/repos/${order.repoFullName}/branches/${enc(order.branchName)}`, { allow404: true });
  if (!branch && order.repoSync?.defaultBranch) branch = await gh(`/repos/${order.repoFullName}/branches/${enc(order.repoSync.defaultBranch)}`, { allow404: true });
  if (!branch) throw new HttpError(409, `Branch ${order.branchName} not found in ${order.repoFullName} yet`);
  queueAudit(order.id, branch.commit.sha, { force: true });
  return { queued: true, sha: branch.commit.sha };
}

/* ------------------------------------------------------------------ 4. Proof Score (reputation from evidence) */
export async function proofScore(devId) {
  const rows = await many(`SELECT id, proof_json, total_cents FROM sg_orders WHERE dev_id=$1 AND paid`, [devId]);
  const s = { orders: rows.length, audited: 0, criteria: 0, proven: 0, modules: 0, modulesReleased: 0, releasedCents: 0, heldCents: 0, audits: 0 };
  for (const { proof_json: p } of rows) {
    if (!p?.audit) continue;
    s.audited++;
    s.audits += (p.history || []).length;
    s.criteria += p.audit.total || 0;
    s.proven += p.audit.counts?.proven || 0;
    for (const e of Object.values(p.escrow || {})) {
      s.modules++;
      if (e.state === 'released') {
        s.modulesReleased++;
        s.releasedCents += e.amountCents || 0;
      } else s.heldCents += e.amountCents || 0;
    }
  }
  s.score = s.criteria ? Math.round((100 * s.proven) / s.criteria) : null;
  return s;
}
