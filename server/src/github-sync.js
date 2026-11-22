// Connect an order to any GitHub repo and keep its tracker in sync automatically:
//  - registers a webhook on the repo when PUBLIC_URL is set (instant updates), and
//  - always polls the GitHub API as a backup, so it also works on localhost with no tunnel.
// Polled state is turned into webhook-shaped events and run through the same FSM + dedupe as real webhooks.
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { config } from './config.js';
import { one, many, query } from './db.js';
import { HttpError } from './auth.js';
import { getOrder, insertMessage, broadcastOrder, setStage } from './services.js';
import { ingestGithub } from './routes/webhooks.js';
import { queueAudit, compileSoon } from './proof.js';

const execFileP = promisify(execFile);
const HOOK_EVENTS = ['create', 'push', 'workflow_run', 'check_suite', 'pull_request', 'deployment_status'];

/* ------------------------------------------------------------------------------- GitHub API */
let cachedToken;
let tokenCheckedAt = 0;
async function githubToken() {
  if (config.githubToken) return config.githubToken;
  // Re-check the CLI login every 2 minutes, so `gh auth login` takes effect without a restart.
  if (cachedToken !== undefined && (cachedToken || Date.now() - tokenCheckedAt < 120_000)) return cachedToken;
  tokenCheckedAt = Date.now();
  try {
    // Falls back to the GitHub CLI login on this machine (never logged or sent anywhere but api.github.com).
    const { stdout } = await execFileP('gh', ['auth', 'token'], { timeout: 5000, windowsHide: true });
    cachedToken = stdout.trim() || null;
  } catch {
    cachedToken = null;
  }
  return cachedToken;
}

// Rate-limit state shared by every call. When GitHub says we're out, we stop calling until the reset.
export const rate = { remaining: null, limit: null, resetAt: 0, authenticated: false };
// ETag cache: conditional GETs that return 304 don't count against GitHub's rate limit.
const etags = new Map(); // path -> { etag, data }

export class RateLimitError extends Error {
  constructor(resetAt) {
    super('GitHub API rate limit reached');
    this.status = 429;
    this.resetAt = resetAt;
  }
}

export async function gh(path, { method = 'GET', body, allow404 = false } = {}) {
  if (rate.resetAt > Date.now() && rate.remaining === 0) throw new RateLimitError(rate.resetAt);
  const token = await githubToken();
  rate.authenticated = !!token;
  const cached = method === 'GET' ? etags.get(path) : null;
  const res = await fetch(`https://api.github.com${path}`, {
    method,
    headers: {
      accept: 'application/vnd.github+json',
      'x-github-api-version': '2022-11-28',
      'user-agent': 'ScopeGuard',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(cached?.etag ? { 'if-none-match': cached.etag } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15_000),
  });

  const remaining = res.headers.get('x-ratelimit-remaining');
  if (remaining !== null) {
    rate.remaining = Number(remaining);
    rate.limit = Number(res.headers.get('x-ratelimit-limit'));
    rate.resetAt = Number(res.headers.get('x-ratelimit-reset')) * 1000;
  }
  if (res.status === 304 && cached) return cached.data;
  if (allow404 && res.status === 404) return null;
  const data = res.status === 204 ? null : await res.json().catch(() => null);
  if ((res.status === 403 || res.status === 429) && (rate.remaining === 0 || /rate limit/i.test(data?.message || ''))) {
    rate.remaining = 0;
    const retryAfter = Number(res.headers.get('retry-after'));
    if (retryAfter) rate.resetAt = Date.now() + retryAfter * 1000;
    throw new RateLimitError(rate.resetAt);
  }
  if (!res.ok) {
    const err = new Error(data?.message || `GitHub HTTP ${res.status}`);
    err.status = res.status;
    throw err;
  }
  const etag = res.headers.get('etag');
  if (method === 'GET' && etag) etags.set(path, { etag, data });
  return data;
}

/** Human, actionable message for a sync failure. */
function syncErrorMessage(e, repo) {
  if (e instanceof RateLimitError) {
    const at = new Date(e.resetAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    return rate.authenticated
      ? `GitHub API limit reached — sync resumes automatically at ${at}.`
      : `GitHub's anonymous limit (60/hour) is used up — sync resumes at ${at}. Add GITHUB_TOKEN or run "gh auth login" for 5,000/hour.`;
  }
  if (e.status === 404) return `Can't see ${repo} — check the repo name, or give the server's GitHub token access to it.`;
  if (e.status === 401) return 'GitHub token is invalid or expired — update GITHUB_TOKEN.';
  if (e.status === 403) return `GitHub denied access to ${repo} — the token needs read access to this repo.`;
  return e.message;
}

export function parseRepo(input) {
  const s = String(input || '').trim().replace(/\.git$/, '').replace(/\/+$/, '');
  const m =
    s.match(/^(?:https?:\/\/)?(?:www\.)?github\.com\/([\w.-]+)\/([\w.-]+)/i) ||
    s.match(/^git@github\.com:([\w.-]+)\/([\w.-]+)$/i) ||
    s.match(/^([\w.-]+)\/([\w.-]+)$/);
  if (!m) throw new HttpError(400, 'Enter a GitHub repo like https://github.com/owner/repo');
  return `${m[1]}/${m[2]}`;
}

/* ------------------------------------------------------------------------- connect / disconnect */
export async function connectRepo(orderId, input) {
  const order = await getOrder(orderId);
  if (!order) throw new HttpError(404, 'Order not found');
  if (!order.paid) throw new HttpError(409, 'Connect a repo after the order is paid');
  const wanted = parseRepo(input);

  let repo;
  try {
    repo = await gh(`/repos/${wanted}`);
  } catch (e) {
    if (e.status === 404) throw new HttpError(404, `Repo ${wanted} not found (or the server's GitHub login can't see it)`);
    throw new HttpError(e instanceof RateLimitError ? 429 : 502, syncErrorMessage(e, wanted));
  }
  const fullName = repo.full_name;

  // Remove a webhook left on a previously linked repo.
  if (order.repoFullName && order.repoFullName !== fullName) await removeHook(order).catch(() => {});

  let hookId = null;
  let hookNote = config.publicUrl ? '' : 'no PUBLIC_URL set — using API polling';
  if (config.publicUrl && config.githubWebhookSecret) {
    const url = `${config.publicUrl}/webhooks/github`;
    try {
      const hooks = await gh(`/repos/${fullName}/hooks?per_page=100`);
      const existing = hooks.find((h) => h.config?.url === url);
      if (existing) {
        hookId = existing.id;
        await gh(`/repos/${fullName}/hooks/${existing.id}`, {
          method: 'PATCH',
          body: { active: true, events: HOOK_EVENTS, config: { url, content_type: 'json', secret: config.githubWebhookSecret } },
        });
      } else {
        const hook = await gh(`/repos/${fullName}/hooks`, {
          method: 'POST',
          body: { name: 'web', active: true, events: HOOK_EVENTS, config: { url, content_type: 'json', secret: config.githubWebhookSecret, insecure_ssl: '0' } },
        });
        hookId = hook.id;
      }
    } catch (e) {
      hookNote = `webhook not registered (${e.status === 404 || e.status === 403 ? 'needs admin access to the repo' : e.message}) — using API polling`;
    }
  }

  const sync = {
    mode: hookId ? 'webhook' : 'polling',
    note: hookNote,
    defaultBranch: repo.default_branch,
    private: repo.private,
    connectedAt: new Date().toISOString(),
  };
  await query('UPDATE sg_orders SET repo_full_name=$2, repo_hook_id=$3, repo_sync_json=$4, updated_at=now() WHERE id=$1', [
    order.id, fullName, hookId, sync,
  ]);
  await insertMessage({
    orderId: order.id,
    senderRole: 'system',
    content: `🔗 GitHub repo ${fullName} connected (${hookId ? 'live webhook' : 'auto-sync'}). The tracker now follows branch \`${order.branchName}\`.`,
  });
  const updated = await broadcastOrder(order.id);
  pollSoon(order.id);
  compileSoon(order.id); // orders paid before Proof-of-Delivery existed get their criteria now
  return updated;
}

async function removeHook(order) {
  if (order.repoFullName && order.repoHookId) {
    await gh(`/repos/${order.repoFullName}/hooks/${order.repoHookId}`, { method: 'DELETE', allow404: true });
  }
}

export async function disconnectRepo(orderId) {
  const order = await getOrder(orderId);
  if (!order) throw new HttpError(404, 'Order not found');
  await removeHook(order).catch(() => {});
  await query(`UPDATE sg_orders SET repo_full_name=NULL, repo_hook_id=NULL, repo_sync_json='{}'::jsonb, updated_at=now() WHERE id=$1`, [order.id]);
  return broadcastOrder(order.id);
}

/* ------------------------------------------------------------------------------------ poller */
const short = (pr) => ({
  number: pr.number,
  title: pr.title,
  html_url: pr.html_url,
  state: pr.state,
  merged: !!pr.merged_at,
  head: { ref: pr.head.ref, sha: pr.head.sha },
  base: { ref: pr.base.ref },
});

async function pollOrder(o) {
  const r = o.repo_full_name;
  const b = o.branch_name;
  const enc = encodeURIComponent;
  const repository = { full_name: r, html_url: `https://github.com/${r}` };
  const ingest = (id, event, payload) => ingestGithub(`poll-${id}`, event, { ...payload, repository });

  const owner = r.split('/')[0];
  const branch = await gh(`/repos/${r}/branches/${enc(b)}`, { allow404: true });
  // PRs are looked up even if the branch is gone: GitHub often deletes the branch right after a merge.
  const prs = await gh(`/repos/${r}/pulls?state=all&head=${enc(`${owner}:${b}`)}&per_page=5`);
  const pr = prs[0];
  if (!branch) {
    if (pr?.merged_at) await ingest(`pr-${pr.number}-merged`, 'pull_request', { action: 'closed', number: pr.number, pull_request: short(pr) });
    return pr ? 'branch deleted' : 'waiting for branch';
  }
  const sha = branch.commit.sha;
  await ingest(`create-${r}-${b}`, 'create', { ref: b, ref_type: 'branch' });
  // Every new commit on the order branch gets a Proof-of-Delivery audit (no-op if this sha was already audited).
  queueAudit(o.id, sha);

  // CI: GitHub Actions first, then any other checks (e.g. third-party CI) via check suites.
  const runs = await gh(`/repos/${r}/actions/runs?branch=${enc(b)}&per_page=10`);
  const forHead = (runs.workflow_runs || []).filter((x) => x.head_sha === sha);
  if (forHead.length) {
    const done = forHead.filter((x) => x.status === 'completed');
    if (done.length === forHead.length) {
      const failed = done.find((x) => x.conclusion !== 'success' && x.conclusion !== 'skipped' && x.conclusion !== 'neutral');
      const run = failed || done[0];
      await ingest(`run-${run.id}-${run.conclusion}`, 'workflow_run', {
        action: 'completed',
        workflow_run: { id: run.id, name: failed || forHead.length === 1 ? run.name : `${done.length} workflows`, head_branch: b, head_sha: sha, conclusion: failed ? run.conclusion : 'success', html_url: run.html_url },
      });
    }
  } else {
    const cs = await gh(`/repos/${r}/commits/${sha}/check-suites`);
    const suites = (cs.check_suites || []).filter((s) => s.app?.slug !== 'github-actions' && s.latest_check_runs_count > 0);
    const noCi = !suites.length && !(runs.workflow_runs || []).length;
    if (noCi !== !!o.no_ci) {
      o.no_ci = noCi;
      await query(`UPDATE sg_orders SET repo_sync_json = repo_sync_json || jsonb_build_object('noCi', $2::boolean) WHERE id=$1`, [o.id, noCi]);
      await broadcastOrder(o.id);
    }
    if (suites.length && suites.every((s) => s.status === 'completed')) {
      const bad = suites.find((s) => !['success', 'neutral', 'skipped'].includes(s.conclusion));
      await ingest(`checks-${sha}-${bad ? bad.conclusion : 'success'}`, 'check_suite', {
        action: 'completed',
        check_suite: { head_branch: b, head_sha: sha, conclusion: bad ? bad.conclusion : 'success', app: { name: (bad || suites[0]).app?.name } },
      });
    }
  }

  if (pr && pr.state === 'open') {
    await ingest(`pr-${pr.number}-open-${pr.head.sha}`, 'pull_request', { action: 'opened', number: pr.number, pull_request: short(pr) });
  }

  // Preview deployments (Vercel/Netlify/etc. post GitHub deployments for the commit or branch).
  if (o.stage >= 2) {
    let [dep] = await gh(`/repos/${r}/deployments?sha=${sha}&per_page=1`);
    if (!dep) [dep] = await gh(`/repos/${r}/deployments?ref=${enc(b)}&per_page=1`);
    if (dep) {
      const [st] = await gh(`/repos/${r}/deployments/${dep.id}/statuses?per_page=1`);
      if (st?.state === 'success' && (st.environment_url || st.target_url)) {
        await ingest(`deploy-${st.id}`, 'deployment_status', {
          deployment_status: { state: 'success', environment_url: st.environment_url || st.target_url, target_url: st.target_url },
          deployment: { ref: b, sha: dep.sha, environment: dep.environment },
        });
      }
    }
  }

  if (pr?.merged_at) {
    await ingest(`pr-${pr.number}-merged`, 'pull_request', { action: 'closed', number: pr.number, pull_request: short(pr) });
  }
  return 'ok';
}

const lastError = new Map();
async function pollOne(o) {
  try {
    await pollOrder(o);
    if (lastError.get(o.id) || o.sync_error) {
      o.sync_error = null;
      lastError.delete(o.id);
      await query(`UPDATE sg_orders SET repo_sync_json = repo_sync_json - 'error' WHERE id=$1`, [o.id]);
      await broadcastOrder(o.id);
    }
  } catch (e) {
    const msg = syncErrorMessage(e, o.repo_full_name);
    if (lastError.get(o.id) !== msg) {
      lastError.set(o.id, msg);
      console.warn(`[github-sync] ${o.id} ${o.repo_full_name}: ${msg}`);
      await query(`UPDATE sg_orders SET repo_sync_json = repo_sync_json || jsonb_build_object('error', $2::text) WHERE id=$1`, [o.id, msg]);
      await broadcastOrder(o.id);
    }
    if (e instanceof RateLimitError) throw e;
  }
}

export function pollSoon(orderId) {
  setTimeout(async () => {
    const o = await one(
      `SELECT id, repo_full_name, branch_name, stage, repo_sync_json->>'error' AS sync_error, (repo_sync_json->>'noCi')::boolean AS no_ci FROM sg_orders WHERE id=$1 AND repo_full_name IS NOT NULL AND paid AND stage BETWEEN 1 AND 5`,
      [orderId],
    );
    if (o) await pollOne(o).catch(() => {});
  }, 300);
}

let running = false;
let lastPoll = 0;
async function tick() {
  if (running) return;
  running = true;
  try {
    await autoAccept();
    const minGap = config.githubPollMs || (rate.authenticated || (await githubToken()) ? 8000 : 60000);
    if (Date.now() - lastPoll < minGap - 500) return;
    if (rate.remaining === 0 && rate.resetAt > Date.now()) return; // wait for the reset quietly
    lastPoll = Date.now();
    const orders = await many(
      `SELECT id, repo_full_name, branch_name, stage, repo_sync_json->>'error' AS sync_error, (repo_sync_json->>'noCi')::boolean AS no_ci FROM sg_orders WHERE repo_full_name IS NOT NULL AND paid AND stage BETWEEN 1 AND 5`,
    );
    for (const o of orders) {
      try {
        await pollOne(o);
      } catch (e) {
        if (e instanceof RateLimitError) break;
      }
    }
  } catch (e) {
    console.warn('[github-sync] tick failed:', e.message);
  } finally {
    running = false;
  }
}

/* ------------------------------------------------------------------ Stage 7 auto-accept timer */
async function autoAccept() {
  if (!(config.autoAcceptHours > 0)) return;
  const due = await many(
    `SELECT id FROM sg_orders WHERE stage = 6 AND (timeline_json->>'6')::timestamptz < now() - make_interval(secs => $1)`,
    [config.autoAcceptHours * 3600],
  );
  for (const { id } of due) {
    await setStage(id, 7, { note: `⏱️ No objections within ${formatHours(config.autoAcceptHours)} of delivery — order auto-accepted and completed.` });
  }
}
export const formatHours = (h) => (h >= 24 ? `${+(h / 24).toFixed(1)} days` : h >= 1 ? `${+h.toFixed(1)} hours` : `${Math.round(h * 60)} minutes`);

export async function startGithubSync() {
  const token = await githubToken();
  const interval = 8000;
  console.log(`  github-sync: ${token ? (config.githubToken ? 'authenticated (GITHUB_TOKEN)' : 'authenticated (gh CLI)') : 'UNAUTHENTICATED — 60 req/hour; set GITHUB_TOKEN or run gh auth login'} · polling every ${token ? 8 : 60}s · webhooks ${config.publicUrl ? 'auto-registered at ' + config.publicUrl : 'off (set PUBLIC_URL to enable)'}`);
  setInterval(tick, interval);
  setTimeout(tick, 2000);
}
