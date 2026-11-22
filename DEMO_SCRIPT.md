# ScopeGuard: Live Judge Demo (about 4 minutes)

## Before judges arrive (5 min)
1. `npm run reset`, then `npm run dev`.
2. **Window A (normal Chrome, left half):** https://scopeguard-poqs.onrender.com (or http://localhost:5173) → click **Client**.
3. **Window B (Incognito, right half):** https://scopeguard-poqs.onrender.com (or http://localhost:5173) → click **Developer**.
4. Have your demo repo cloned in a terminal, with `demo-repo-template/.github/workflows/ci.yml` committed to it. No tunnel needed.
5. Keep the Stripe test card ready: `4242 4242 4242 4242` · `12/30` · `123`.

---

## 1. Hook (15s)
> "Clients don't know what software costs, and agencies lose money to scope creep. ScopeGuard lets clients order software like food, track it like a delivery, and it guards the scope with AI."

## 2. Two real portals (10s)
Point at both windows: real JWT logins with roles. The **client** sees New Project / My Orders. The **dev** sees the Agency Queue (status chips show AI, Stripe and GitHub connected).

## 3. One cart: menu + custom, client (50s)
- A: **New Project**. Step 1: click the brief chip *"I run a dental clinic with 3 dentists…"* (every order starts with a project brief).
- Step 2: **Add** *Landing Page* and *Auth Module* (fixed price), then **Add** the ✨ **Custom feature** card → chip *"AI chatbot that answers patient FAQs"*.
- The cart shows **$550 + custom** → **Get my AI quote →**.
> "Fixed-price features and custom work in one cart. A menu-only cart goes straight to checkout."
- The AI asks 3–4 questions about the custom part only. Click an answer chip for each one.
- Questions take ~12s and the quote ~35s (free Nemotron 3 Ultra). Talk over the staged progress.
- The quote shows the 🍽️ menu items at their fixed prices plus the AI-priced custom modules. Click **Open order CD-1042**.
> "That's NVIDIA Nemotron 3 Ultra through OpenRouter. It scopes only the custom work, keeps menu prices fixed, and writes one brief with explicit in-scope and out-of-scope items."

## 4. Dev reviews the quote (25s)
- B: a toast says **"New AI quote · CD-1042"** → click it.
- Change one price, then **Approve & Send to Client**.
- A updates instantly to **Your Quote v1**.

## 5. Live negotiation (45s)
- A: switch off 1–2 **optional** modules → the total drops live.
- A chat: *"Can we swap the full FAQ training for a cheaper CSV upload around $250?"*
- B: set that module to `250`, note *"Swapped to CSV upload"* → **Push Revision**.
- A: the quote flashes **"Revised live"** to v2, and a revision card shows the diff.
- A: **Accept & Pay** → Stripe Checkout → test card → **Pay**.
- Back on A: **"Payment confirmed"**, then **Paid & Queued**, with the scope hash shown.
> "One-go payment. The exact modules paid for are hashed and locked."

## 6. Build tracker (60s)
- B: toast **"Paid · CD-1042"** → open it → paste your repo URL in **Connect a GitHub repo** → **Connect** (shows ● Auto-sync on) → **Accept Order** → the git commands for this order appear.
> "Any GitHub repo. The server watches it, so nobody clicks 'next stage'."
- **Live GitHub path** (terminal):
  ```bash
  git checkout -b order/CD-1042 && git commit --allow-empty -m start && git push -u origin order/CD-1042
  gh pr create --base main --head order/CD-1042 --fill
  gh pr merge --merge
  ```
- **Failsafe path:** B → **Ctrl+K** → click in order: *Branch created → CI failed → CI passed → PR opened → Preview deployed*.
- A animates live: Cooking → **red CI failure** → Quality Check → Out for Delivery → Taste Test (with an **Open preview** button).
> "Every step is a real GitHub webhook, HMAC-verified and de-duplicated. Nobody clicks 'next stage'."

## 7. ScopeGuard (45s): the wow moment
- A chat: *"Can you also add Google Calendar booking so patients pick a slot?"*
- B, about 4s later: a red **🚩 Potential Scope Change** appears with the AI's reason and a suggested price. **The client never sees this.**
- B: click **Price add-on…** (prefills the form) → set `$350` → **Send "Add to Order" card**.
- A: the card appears → **Pay & Add** → Stripe → paid → scope re-hashed, total goes up.
- Contrast: A asks *"What's the ETA on the widget?"* → B shows **🛡️ In scope**.

## 8. Delivery (20s)
- Live: `gh pr merge` · Failsafe: Ctrl+K → **PR merged**.
- A: **📦 Delivered** → **Accept Delivery** → **🎉 Completed**.

## 9. Close (10s)
> "AI scoping, live negotiation, one-go payment, a GitHub-driven tracker, and AI scope protection, all real-time."

---

## If something goes wrong
| Problem | Do this |
| --- | --- |
| Wi-Fi or GitHub slow | Ctrl+K replay (same state machine, recorded real payloads) |
| AI slow | Quote normally takes ~35s on the free model. After 60s it switches to Claude Haiku automatically |
| A window looks stale | Refresh. State comes from the DB and the socket rejoins |
| Need a clean slate | `npm run reset` (restart not needed) |
