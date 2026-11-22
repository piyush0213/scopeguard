import crypto from 'node:crypto';
import { config } from './config.js';
import { one } from './db.js';
import { setStage } from './services.js';

export function verifySignature(rawBody, signatureHeader) {
  if (!config.githubWebhookSecret) return false;
  if (!signatureHeader?.startsWith('sha256=')) return false;
  const expected = 'sha256=' + crypto.createHmac('sha256', config.githubWebhookSecret).update(rawBody).digest('hex');
  const a = Buffer.from(expected);
  const b = Buffer.from(signatureHeader);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const stripRef = (ref = '') => ref.replace(/^refs\/heads\//, '');

/** Work out which branch a GitHub event refers to. */
export function branchOf(event, p) {
  switch (event) {
    case 'create':
    case 'delete':
      return p.ref_type === 'branch' ? p.ref : null;
    case 'push':
      return stripRef(p.ref);
    case 'workflow_run':
      return p.workflow_run?.head_branch;
    case 'check_suite':
      return p.check_suite?.head_branch;
    case 'pull_request':
      return p.pull_request?.head?.ref;
    case 'deployment_status':
      return p.deployment?.ref ? stripRef(p.deployment.ref) : null;
    default:
      return null;
  }
}

/**
 * The 7-stage FSM, shared by real webhooks, the repo poller and demo replay. Returns { orderId, applied, detail }.
 *   1 Order Accepted (dev)  · 2 Cooking (branch create/push) · 3 Quality Check (workflow_run/check_suite success)
 *   4 Out for Delivery (PR opened) · 5 Taste Test (deployment_status success / preview attached)
 *   6 Delivered (PR merged) · 7 Completed (client accepts or auto-accept timer).
 * Forward-only, except a CI failure reverts to Cooking with a red flag.
 */
const CI_FAIL = ['failure', 'timed_out', 'cancelled', 'startup_failure', 'action_required'];

export async function applyGithubEvent(event, p) {
  const branch = branchOf(event, p);
  if (!branch) return { orderId: null, applied: false, detail: 'no branch in event' };
  const order = await one('SELECT id, stage, paid, ci_failed, repo_full_name FROM sg_orders WHERE branch_name=$1', [branch]);
  if (!order) return { orderId: null, applied: false, detail: `no order for branch ${branch}` };
  const repo = p.repository?.full_name || order.repo_full_name || 'repo';
  if (order.repo_full_name && p.repository?.full_name && p.repository.full_name.toLowerCase() !== order.repo_full_name.toLowerCase()) {
    return { orderId: order.id, applied: false, detail: `event from ${repo}, order is linked to ${order.repo_full_name}` };
  }
  if (!order.paid) return { orderId: order.id, applied: false, detail: 'order not paid yet' };
  if (order.stage < 1) return { orderId: order.id, applied: false, detail: 'waiting for the dev to accept the order' };
  if (order.stage >= 7) return { orderId: order.id, applied: false, detail: 'order already completed' };

  let r = null;
  const ci = (name, conclusion) =>
    conclusion === 'success'
      ? setStage(order.id, 3, { set: { ci_failed: false }, note: `✅ Quality Check passed — "${name}" is green.` })
      : CI_FAIL.includes(conclusion)
        ? setStage(order.id, 2, {
            force: order.stage > 2,
            announce: !order.ci_failed, // webhook + poller may both report the same failure
            set: { ci_failed: true },
            note: `❌ CI "${name}" ${conclusion}. Back to Cooking while the dev fixes it.`,
          })
        : null;

  if (event === 'create' || (event === 'push' && !p.deleted)) {
    const sha = p.after ? ` @ ${p.after.slice(0, 7)}` : '';
    r = await setStage(order.id, 2, {
      note: `👨‍🍳 Cooking — branch \`${branch}\` ${event === 'create' ? 'created' : 'received commits'} on ${repo}${sha}.`,
    });
  } else if (event === 'workflow_run' && p.action === 'completed') {
    r = await ci(p.workflow_run.name || 'CI', p.workflow_run.conclusion);
  } else if (event === 'check_suite' && p.action === 'completed') {
    r = await ci(p.check_suite.app?.name || 'Checks', p.check_suite.conclusion);
  } else if (event === 'pull_request') {
    const pr = p.pull_request;
    if (['opened', 'reopened', 'ready_for_review', 'synchronize'].includes(p.action) && pr.state !== 'closed') {
      r = await setStage(order.id, 4, {
        set: { pr_url: pr.html_url },
        note: `🛵 Out for Delivery — PR #${pr.number} "${pr.title}" ${p.action === 'synchronize' ? 'updated' : 'opened'}.`,
      });
    } else if (p.action === 'closed' && pr.merged) {
      r = await setStage(order.id, 6, {
        set: { pr_url: pr.html_url, ci_failed: false },
        note: `📦 Delivered — PR #${pr.number} merged into \`${pr.base?.ref || 'main'}\`. Please review and accept delivery.`,
      });
    }
  } else if (event === 'deployment_status' && p.deployment_status?.state === 'success') {
    const url = p.deployment_status.environment_url || p.deployment_status.target_url;
    if (url) r = await setStage(order.id, 5, { set: { preview_url: url }, note: `😋 Taste Test — preview is live: ${url}` });
  }
  return { orderId: order.id, applied: !!r, detail: r ? `now ${r.status}` : 'no stage change' };
}
