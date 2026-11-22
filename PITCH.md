# ScopeGuard — Pay for proof, not promises

## The USP in one line
**ScopeGuard is the first software marketplace where money moves only when the code proves it.**
Every paid item sits in escrow. An AI auditor reads every commit in the developer's GitHub repo and releases each
item's money only when it finds the feature working in the code, citing the exact file and line. Anything never
proven is refunded.

## Why Upwork and Fiverr can't do this
| | Upwork / Fiverr | ScopeGuard |
|---|---|---|
| What triggers payment | A client clicks "approve", or a timer runs out (Upwork auto-releases a fixed-price milestone if the client doesn't respond in 14 days) | Evidence in the code: every acceptance criterion proven at a real file + line |
| What the contract is | A text description | An executable contract: priced modules → machine-checkable acceptance criteria → hashed |
| How disputes end | Dispute specialists, then paid arbitration | Mostly they don't start: both sides see the same evidence, item by item |
| When the developer is paid | At the end of a milestone, after approval | The minute each module is proven |
| Reputation | Star reviews (can be bought, or tanked by one unfair client) | **Proof Score**: % of contract criteria proven in code, can't be faked |
| Scope creep | Handled in chat, unpriced | AI flags out-of-scope requests and turns them into a priced add-on |
| Where the work lives | Files uploaded at the end | In the client's repo from the first commit |

They're horizontal people-marketplaces (design, writing, video…). Payment-on-evidence needs the deliverable to be
code, the scope to be machine-checkable from the moment of purchase, and the repo connected from day one. That's
our whole pipeline, not a feature they can bolt on.

## How it works (the pipeline)
1. **Order like food.** Fixed-price menu items (Auth, Landing page, Stripe, Admin) plus custom work scoped and priced by AI.
2. **Executable contract.** On payment the scope is locked (SHA-256) and compiled into 2–4 acceptance criteria per item. The criteria describe *what* the software must do, never *how*, so any stack counts (Supabase auth passes an auth criterion).
3. **Escrow per item.** The money is held line by line, not as one lump.
4. **Every push is audited.** ScopeGuard watches the order branch. On each new commit it fetches up to 70 source files (the developer's changed files first), and the AI auditor judges each criterion: proven / in progress / not found.
5. **Anti-hallucination.** The AI must cite a file and line range. ScopeGuard checks that citation against the real files; a citation that doesn't exist is rejected and doesn't count. The evidence the client sees is the real code, pulled from GitHub, not AI text.
6. **Release.** When all of an item's criteria are proven (and CI isn't red), that item's escrow is released to the developer, with a chat message like *"🔓 Escrow released: $300 for Landing Page, all 4 criteria proven (e.g. public/index.html:16)"*.
7. **Refund.** At completion, anything never proven shows as refund due to the client.
8. **Proof Score.** Each developer's reputation is computed from audited evidence across all their orders.

## Proven in testing (real runs, real repos)
- **A public Next.js + Supabase + Stripe starter (vercel/nextjs-subscription-payments)**, with a contract including an iOS app that was never built: the auditor read 69 files. Real sign-up, GitHub OAuth and the Stripe webhook were proven with exact file + line. The iOS app was marked "not found" on all 4 criteria and its money stayed held.
- **Same repo, a contract it actually fulfils** (Auth + Pricing page): 6/6 criteria proven, $550 released automatically, Proof Score 100.
- **The live demo kit (BrightSmile Dental)**: push 1 (landing page only) → Landing Page released, Auth held. Push 2 (adds auth) → Auth released.

## 2-minute speech
> Judges, last round you told us Upwork and Fiverr could do what we showed. You were right. So we rebuilt ScopeGuard around one thing they structurally can't do.
>
> On every freelance platform today, money moves when someone clicks "approve", or when a timer runs out. Not when the work exists. Clients pay for things that were never built. Developers wait weeks for approval from people who can't read code. And when it goes wrong, it's a dispute, then arbitration.
>
> **ScopeGuard pays for proof, not promises.**
>
> When a client orders, the scope becomes an executable contract: every item is broken into acceptance criteria. The money goes into escrow, line by line. Then the developer just codes, as usual, in GitHub. On every push, our AI auditor reads the actual source code and checks each criterion. When an item is proven, its money is released to the developer that minute. The client sees the exact file and line that proves it.
>
> And the AI can't bluff: every citation is checked against the real repo. If the file or line doesn't exist, it doesn't count.
>
> *[push step 1 live]* Watch: the developer just pushed the landing page. ScopeGuard is reading the commit… Landing Page: four criteria proven, here's the code. $300 released. Auth is still held, because it isn't there yet. *[push step 2]* Now auth… released.
>
> Anything never built is refunded. And every developer gets a Proof Score: reputation computed from verified code, not reviews someone can buy.
>
> Upwork sells access to people. We sell verified outcomes. That's the company.

## Live demo runbook (about 5 minutes)
1. Open https://scopeguard-poqs.onrender.com (or http://localhost:5173 locally). The landing page reads "Pay for proof, not promises."
2. Sign in as **Developer**, open **CD-1049** (Auth Module + Landing Page, already paid and accepted).
3. In Build controls, connect `https://github.com/piyush0213/Dental`. The Proof Vault shows $550 held and compiles the criteria (about 10–20 s).
4. In a second window, sign in as **Client** and open CD-1049 to show the client's view of the same vault.
5. In PowerShell:
   ```powershell
   cd C:\Users\Piyush\OpenBot\Agents\agent-2b2a23c7-b663-42a2-80f9-40ae61e2f052\scopeguard\demo-kit
   .\push-step.ps1 -Repo C:\Users\Piyush\Dental -Branch order/CD-1049 -Step 1
   ```
   Within about 8 s the tracker moves to Cooking and the audit starts. It takes about 1–2 minutes (fill this time with the speech). Landing Page → **Released**, with evidence. Auth → **Held**.
6. Show the Scope Shield in chat while waiting: as the client, ask "Can you also add Google Calendar sync?" The developer sees a priced add-on suggestion.
7. Push step 2 (`-Step 2`). Auth → **Released**. The ledger shows $550 released and the developer's Proof Score goes up.
8. Backup if Wi-Fi or the AI is slow: press **↻ Audit latest commit** to retry. Replay (Ctrl+K) still drives the tracker stages.

## Business model
- **Take rate on escrow** (Upwork today: a variable 0–15% freelancer fee plus a 5% client marketplace fee).
- **Agency plan (SaaS):** agencies plug ScopeGuard escrow and audits into their own client contracts, off-marketplace.
- **Audit API:** "proof of delivery" for any code contract, e.g. for procurement, grants and bounties.
- **Moat:** every audited (contract, code, verdict) record improves pricing and auditing, and Proof Score is a reputation that only exists here.

## Likely questions
- **"What if the AI is wrong?"** It can't invent evidence: citations are verified against the repo, and the client sees the real code. Releases need *every* criterion proven, and CI must be green. Either party can re-run an audit. Next step: a human-review appeal on any single criterion.
- **"Can a developer game it with fake code?"** The auditor is told that comments, TODOs, placeholders, mocked returns and README claims don't count. Releases are final, so gaming would have to survive a strict audit first. Next step: also run the project's tests in CI as part of the proof.
- **"Is the escrow real?"** Payments are real Stripe test-mode charges. In this build, the per-item release is recorded in ScopeGuard's escrow ledger. In production each release would be a Stripe Connect transfer to the developer.
- **"Privacy of private repos?"** The server reads code with a token scoped to the repo, sends only the relevant files to the model, and stores just the cited lines.

## Sources for the comparison claims
- Upwork 14-day auto-release and dispute path: https://support.upwork.com/hc/en-us/articles/211062068 , https://www.upwork.com/resources/upwork-dispute-process
- Upwork fees (variable 0–15% freelancer fee since May 2025, 5% client fee): https://www.upwork.com/pricing , https://support.upwork.com/hc/en-us/articles/4660220468499
- Standish CHAOS (most software projects historically late, over budget or short on features): https://www.classes.cs.uchicago.edu/archive/2014/fall/51210-1/required.reading/Standish.Group.Chaos.2009.pdf

## Track 1 — "Here, together": Scope Room
**The problem in the room:** scope fights start at the kickoff meeting. Five people nod at a slide, everyone
remembers a different scope, and three weeks later it's "but you said…".

**Scope Room:** the agency opens the order on the big screen; everyone in the meeting scans the QR and joins from
their own phone — client, developers, the client's co-founder (no account needed). The bill is live on every phone.
The client switches an optional item off: every phone's total drops instantly. Each person taps **Agree**. The moment
everyone present agrees, every phone lights up in a wave around the table, and the agreement — who, which version,
which fingerprint — is stored and posted to the order. Change anything later and the agreement resets. Then the client
pays into escrow, and the Proof Vault takes over.

**Why it needs Serverpod:** one streaming connection per phone, server events fan out per room, presence from open
streams, the server owns the agreement and the clock (the wave is synchronized across devices), and Postgres keeps the
permanent agreement record. Web and Flutter share one source of truth.

**Demo (2 minutes, laptop + 2 phones):**
1. Laptop (projector): Flutter app as Client → My orders → open an order with a quote → **Open** Scope Room. QR on screen.
2. Two judges scan → their names pop onto the projector (one as guest, one signed in as Developer).
3. Client switches an optional item off → judges watch their totals change → "any change resets agreement".
4. Everyone taps Agree → 2.5 s countdown → the light travels phone to phone. *Rehearse this.*
5. Switch to the website tab: the order chat shows "🤝 Scope agreed in person … by …".
6. Client taps "Pay into escrow" → Proof Vault story (main pitch above).
