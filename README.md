# ScopeGuard

**Pay for proof, not promises.** Clients order software the way they order food, track the build like a delivery,
and their money is released feature by feature only when an AI auditor finds each feature working in the real GitHub code.

## Live demo

| | Link |
|---|---|
| **Flutter app** (Serverpod Cloud) — includes **Scope Room**, Track 1 | https://scopeguard.serverpod.space |
| Serverpod API | https://scopeguard.api.serverpod.space |
| **Website** (React + Node, Render) | https://scopeguard-poqs.onrender.com |

Demo accounts: `client@demo.dev` / `dev@demo.dev`, password `demo1234` (one-tap buttons on the sign-in screen).
Stripe is in test mode: card `4242 4242 4242 4242`, any future date, any CVC.
The website runs on Render's free plan, so the first load after 15 idle minutes takes about 50 seconds.
Both front ends share the same data: an order placed in the Flutter app appears on the website, and the other way round.

**Try Scope Room (Track 1):** sign in as Client on one phone, open order CD-1050, tap **Open** on the Scope Room card.
On a second phone scan the QR (or join with the 4-letter code). Toggle an optional item and watch every phone's total
change live; when everyone taps **I agree**, all phones light up in sync and the agreement is posted to the order chat.
React + Vite · Express + Socket.IO · PostgreSQL · OpenRouter (Claude) · Stripe (test mode) · GitHub webhooks

- **Real JWT auth + RBAC** with `client` and `dev` roles and separate portals (`/client/*`, `/dev/*`).
- **One cart for everything:** every order starts with a project brief. Fixed-price menu items and a custom feature go in the same cart. Menu-only carts go straight to checkout; anything custom goes through AI scoping with the menu items pre-priced in the same quote.
- **AI scoping:** the AI (OpenRouter, default `nvidia/nemotron-3-ultra-550b-a55b:free` (free), with `anthropic/claude-haiku-5.5` as backup) asks 3–4 questions, then returns a JSON brief and priced modules.
- **Live negotiation:** the dev edits prices and pushes a revision, and the client's quote updates instantly. The client toggles optional modules, and the dev sees the new total live.
- **One-go Stripe Checkout** (`capture_method: automatic`). The paid module snapshot is locked with a SHA-256 `scope_hash`.
- **7-stage tracker driven by real GitHub webhooks.** Each webhook is checked with an HMAC (`X-Hub-Signature-256`) and deduplicated by `X-GitHub-Delivery`. A CI failure turns the tracker red and moves it back to Cooking.
- **ScopeGuard:** each client message on a paid order is checked by the AI against the locked brief. Out-of-scope requests are flagged to the **dev only**, with a suggested add-on and price. One click sends a priced "Add to Order" card. The client pays in one go or skips, and the scope is re-hashed.
- **Demo failsafe:** `Ctrl/Cmd+K` in the dev workspace re-fires the last *recorded* GitHub payloads through the same state machine.

## Run locally

```bash
npm run install:all
npm run dev            # API :4000 + web :5173
npm run reset          # wipe test orders before the pitch (next order = CD-1042)
```

Open http://localhost:5173. For the pitch, run Client in a normal window and Dev in Incognito.
Demo accounts: `client@demo.dev` / `dev@demo.dev`, password `demo1234` (one-click buttons on the login page).
Stripe test card: `4242 4242 4242 4242`, any future date, any CVC.

### Configuration: `server/.env`

| Var | Purpose |
| --- | --- |
| `KEYS_DIR` | Folder with one file per secret (`DATABASE_URL`, `GEMINI_API_KEY`, `STRIPE_SECRET_KEY`, …). Keeps keys out of the repo. You can also set the env vars directly. |
| `DATABASE_URL` | Postgres. Tables are prefixed `sg_` and auto-migrate and seed on boot. |
| `OPENROUTER_API_KEY`, `OPENROUTER_MODEL` | Primary AI. `OPENROUTER_MODEL` is a comma-separated list tried in order (default `nvidia/nemotron-3-ultra-550b-a55b:free,anthropic/claude-haiku-5.5`). `OPENROUTER_TIMEOUT_MS` (default 60000) per model. |
| `GEMINI_API_KEY`, `GEMINI_MODEL` | Optional automatic backup if every OpenRouter model fails. |
| `STRIPE_SECRET_KEY` | Test-mode key. |
| `STRIPE_WEBHOOK_SECRET` | Optional. Payments are also confirmed server-side with Stripe when the client returns from Checkout, so the app works without webhooks. |
| `GITHUB_WEBHOOK_SECRET` | HMAC secret. Already generated in `server/.env`. |
| `GITHUB_REPO` | `owner/name` of the demo repo (shown in the dev's git instructions). |
| `APP_URL` | Where Stripe redirects back to (default `http://localhost:5173`). |
| `PUBLIC_URL` | Optional public API URL. Enables automatic webhook registration when a repo is connected. |
| `GITHUB_TOKEN` | Optional. Defaults to your `gh auth login` session. Used for repo sync. |
| `AUTO_ACCEPT_HOURS` | Stage 7 auto-accept delay (default 72, `0` disables). |

## Live GitHub tracker: connect any repo

In the dev workspace, open a paid order, go to **Build controls → Connect a GitHub repo**, and paste your repo URL (`https://github.com/you/app`). That's it.

- **Auto-sync (always on):** the server polls the GitHub API every 8s for the order's branch `order/CD-XXXX`. It works on localhost with no tunnel. It authenticates with `GITHUB_TOKEN` or, if that's unset, your local `gh auth login` session.
- **Live webhook (optional, instant):** set `PUBLIC_URL` (e.g. from `npm run tunnel`). Connecting a repo then registers a webhook on it automatically (needs admin rights on the repo).
- Both feed the same HMAC-verified, de-duplicated state machine:

| Stage | Trigger | Status |
| --- | --- | --- |
| 1 | Dev clicks **Accept Order** | Order Accepted |
| 2 | Branch `order/CD-XXXX` created/pushed | Cooking |
| 3 | CI passes (`workflow_run` or `check_suite` success). A failure turns it red and reverts to Cooking | Quality Check |
| 4 | Pull request opened from the branch | Out for Delivery |
| 5 | Preview deployed (`deployment_status` success, e.g. Vercel/Netlify) or URL attached in the dev UI | Taste Test |
| 6 | PR merged (detected even if GitHub deletes the branch) | Delivered |
| 7 | Client clicks **Accept Delivery**, or auto-accept after `AUTO_ACCEPT_HOURS` (default 72) | Completed |

Copy `demo-repo-template/.github/workflows/ci.yml` into your repo for CI (commit a `FAIL_CI` file to show the red state). The dev workspace shows the exact git commands for each order.

Optional Stripe webhook: in the dashboard, point an endpoint at `https://xxxx.ngrok-free.app/webhooks/stripe` (event `checkout.session.completed`), then put its `whsec_…` in `STRIPE_WEBHOOK_SECRET`.

## Single-origin deploy (Render / Railway)

`npm run install:all && npm run build`, then `npm start`. Express serves `client/dist` and the API from one origin. Set `APP_URL` to the public URL.

## API

Auth: `POST /api/auth/register|login`, `GET /api/auth/me`
Client: `GET /api/menu`, `POST /api/orders/menu`, `POST /api/orders/custom/scope`, `PATCH /api/orders/:id/toggles`, `POST /api/orders/:id/checkout`, `POST /api/orders/:id/addons/:addonId/pay|skip`, `POST /api/orders/:id/client-accept`, `POST /api/payments/verify`
Dev: `GET /api/dev/orders`, `PATCH /api/quotes/:id/approve|revise`, `POST /api/orders/:id/accept|addons|preview`, `POST|DELETE /api/orders/:id/repo`
Shared: `GET /api/orders/:id`, `POST /api/orders/:id/messages`
System: `POST /webhooks/stripe`, `POST /webhooks/github`, `GET|POST /demo/replay/:orderId[/:stage]`
Socket.IO (JWT handshake): `order:join`, `chat:send`, `chat:message`, `chat:typing`, `quote:revised`→`order:updated`, `scope:flagged` (dev-only), `quote:new`, `order:paid`, `scope:alert`

## Proof-of-Delivery escrow (the USP)
Money moves only when the code proves it. See `PITCH.md` for the pitch, comparison and live-demo runbook.

- On payment (or when a repo is connected) the locked scope is compiled into 2–4 behaviour-level acceptance criteria per module (`server/src/proof.js`, `compileCriteria` in `ai.js`).
- Every new commit on the order branch triggers an audit: up to 70 source files are fetched from GitHub (changed files first), the AI judges each criterion, and every citation is checked against the real file before it counts.
- A module's escrow is released when all its criteria are proven and CI isn't red. Unproven modules show as refund due when the order completes.
- `POST /api/orders/:id/proof/audit` re-runs an audit; `GET /api/proof-score/:devId` returns the developer's evidence-based Proof Score.
- `demo-kit/` holds a two-step demo app (landing page, then auth) and `push-step.ps1` to push each step live.
- Tests: `node server/scripts/proof-test.mjs owner/repo [--release]` (real audit through the API), `node server/scripts/kit-test.mjs` (dry-run of the demo kit, no push).

## Flutter version + Track 1 "Here, together": Scope Room
ScopeGuard now ships as **two front ends on the same data**:

| | Website | Flutter app (Android + web) |
|---|---|---|
| Stack | React + Node (`client/`, `server/`) | Flutter + **Serverpod 4** (`scopeguard_app/`) |
| URL (local) | http://localhost:5173 | http://localhost:8082 |
| Accounts, orders, AI quotes, Stripe, GitHub tracking, Proof Vault | ✓ | ✓ (via Serverpod → ScopeGuard core API) |
| Scope Room (Track 1) | sees the result in the order chat | ✓ live, multi-device |

An order made in the app shows up on the website and vice versa; both use the same accounts.

**Scope Room** — everyone at the kickoff meeting (client, developers, the client's co-founder…) joins one order
from their own phone by 4-letter code or QR. Everyone sees the bill live; the client switches optional items and
every phone updates instantly. Each person taps **Agree**. When everyone present agrees to the same version, every
phone lights up in a synchronized wave around the table, the agreement (signers, quote version, sha256 fingerprint)
is stored in Serverpod's Postgres and posted into the order chat on the website. Any later change to the quote —
from the room or the website — resets the agreement. Then the client pays into escrow from their phone.

Serverpod pieces (`scopeguard_app/scopeguard_app_server/lib/src/`):
- `scope_room/` — tables `scope_room`, `room_member`, `scope_agreement`; streaming method `watch` + server events
  channel per room; presence (open stream = present); server-decided lock time with client clock-offset sync;
  secret per-member tokens and ScopeGuard tokens kept `serverOnly`.
- `scopeguard/` — `account`, `shop`, `orders` (incl. live `watch` stream), `kitchen` endpoints that call the
  ScopeGuard core API, so the Flutter app talks only to Serverpod.

### Run everything
```powershell
cd C:\Users\Piyush\OpenBot\Agents\agent-2b2a23c7-b663-42a2-80f9-40ae61e2f052\scopeguard
.\start-all.ps1          # website + core API + Serverpod + Flutter web app
.\start-all.ps1 -Web     # rebuild the Flutter web app first (after changing app code)
.\start-all.ps1 -Stop
```
Do **not** use `serverpod start` on this laptop: unpacking Serverpod's embedded-Postgres download caused two blue
screens. `start-all.ps1` runs a private Postgres 18 cluster from the installed PostgreSQL (`scopeguard_app_server\.pgdev`,
port 8090) and everything at below-normal priority. Flutter SDK for this project: `E:\flutter\flutter-sp4` (3.50.1).

**Phones (any network):** `.\start-all.ps1 -Public` also opens a temporary public https link (Cloudflare quick
tunnel, `tools\cloudflared.exe`) and prints it, e.g. `https://xxxx.trycloudflare.com`. Open it on any phone — college
Wi-Fi blocks phone-to-laptop traffic, so the plain Wi-Fi address usually does not work there. A new link is made on each
start; anyone with the link can open the app while it runs; `.\start-all.ps1 -Stop` closes it.
How it works: `tools\mobile-gateway.mjs` (port 8088) serves the Flutter web app and forwards app calls and live
streams (WebSockets) to Serverpod on one address; the tunnel runs with `--protocol http2` because the network blocks QUIC.
The gateway strips Serverpod's `content-length: 0` from the WebSocket upgrade reply — without that, Cloudflare never
delivers server-to-phone frames and live screens time out.
After paying on a phone, Stripe returns to the website address (localhost), which a phone can't open: go back to the
app and tap **"I paid on Stripe — confirm payment"**.

Native Android build (optional): `flutter build apk --dart-define=SERVER_URL=https://<public-link>/`.

**Test:** `scopeguard_app\scopeguard_app_flutter\tool\e2e.dart` (23 checks: sign-in, AI scoping, dev approval,
3-phone room with roles and permissions, live toggles, agreement, website chat note, website price change re-opens
the room, live order stream, end). Run with `E:\flutter\flutter-sp4\bin\cache\dart-sdk\bin\dart.exe run tool/e2e.dart`
in `scopeguard_app_flutter` while start-all.ps1 is running. It creates one real test order (AI call).
