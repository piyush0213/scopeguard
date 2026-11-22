// Fallback payloads (GitHub webhook shape, trimmed) used by /demo/replay only when no real
// delivery of that kind has been recorded yet. Real deliveries are always preferred.
const BRANCH = 'order/CD-0000';
const repository = { full_name: 'scopeguard-demo/app', html_url: 'https://github.com/scopeguard-demo/app' };
const sender = { login: 'agency-dev' };
const pr = (extra) => ({
  number: 1,
  title: `Deliver ${BRANCH}`,
  html_url: 'https://github.com/scopeguard-demo/app/pull/1',
  head: { ref: BRANCH, sha: 'a1b2c3d4e5f6' },
  base: { ref: 'main' },
  merged: false,
  ...extra,
});

export const fixtures = {
  2: { ref: BRANCH, ref_type: 'branch', master_branch: 'main', repository, sender },
  3: {
    action: 'completed',
    workflow_run: { name: 'CI', head_branch: BRANCH, status: 'completed', conclusion: 'success', html_url: `${repository.html_url}/actions` },
    repository,
    sender,
  },
  ci_fail: {
    action: 'completed',
    workflow_run: { name: 'CI', head_branch: BRANCH, status: 'completed', conclusion: 'failure', html_url: `${repository.html_url}/actions` },
    repository,
    sender,
  },
  4: { action: 'opened', number: 1, pull_request: pr(), repository, sender },
  5: {
    deployment_status: { state: 'success', environment: 'Preview', environment_url: 'https://scopeguard-demo-preview.vercel.app' },
    deployment: { ref: BRANCH, environment: 'Preview' },
    repository,
    sender,
  },
  6: { action: 'closed', number: 1, pull_request: pr({ merged: true }), repository, sender },
};
