import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { money, totalOf, clock } from '../lib/api.js';

export const STAGES = [
  { label: 'Paid & queued', icon: '00', desc: 'Payment confirmed, scope locked' },
  { label: 'Order accepted', icon: '01', desc: 'A developer picked up your order' },
  { label: 'Cooking', icon: '02', desc: 'Code is being written on the order branch' },
  { label: 'Quality check', icon: '03', desc: 'Automated tests passed' },
  { label: 'Out for delivery', icon: '04', desc: 'Pull request opened for review' },
  { label: 'Taste test', icon: '05', desc: 'Preview deployment ready to try' },
  { label: 'Delivered', icon: '06', desc: 'Merged into main' },
  { label: 'Completed', icon: '07', desc: 'Delivery accepted' },
];

const STATUS = {
  scoping: ['Scoping', 'text-stone-500', 'bg-stone-400'],
  ai_draft: ['Being reviewed', 'text-stone-700', 'bg-amber-500'],
  negotiating: ['Quote ready', 'text-stone-700', 'bg-sky-600'],
  awaiting_payment: ['Awaiting payment', 'text-stone-500', 'bg-stone-400'],
  paid: ['Paid', 'text-leaf', 'bg-leaf'],
  accepted: ['Accepted', 'text-leaf', 'bg-leaf'],
  cooking: ['Cooking', 'text-brand-600', 'bg-brand-500'],
  quality_check: ['Quality check', 'text-brand-600', 'bg-brand-500'],
  out_for_delivery: ['Out for delivery', 'text-brand-600', 'bg-brand-500'],
  taste_test: ['Taste test', 'text-brand-600', 'bg-brand-500'],
  delivered: ['Delivered', 'text-leaf', 'bg-leaf'],
  completed: ['Completed', 'text-ink', 'bg-ink'],
};

export function StatusBadge({ order }) {
  const [label, text, dot] = STATUS[order.status] || [order.status, 'text-stone-500', 'bg-stone-400'];
  const failing = order.ciFailed && order.paid;
  const live = ['cooking', 'quality_check', 'out_for_delivery', 'taste_test', 'ai_draft'].includes(order.status);
  return (
    <span className={`inline-flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.14em] ${failing ? 'text-brand-600' : text}`}>
      <span className={`h-1.5 w-1.5 rounded-full ${failing ? 'bg-brand-500' : dot} ${live ? 'animate-pulse' : ''}`} />
      {failing ? 'CI failing' : label}
    </span>
  );
}

/* ---------------------------------------------------------------------------------- NextStep */
/** Plain-language "what happens next" for the current order state, per role. */
function nextStep(o, role) {
  const branch = o.branchName;
  if (role === 'client') {
    if (o.status === 'scoping') return null;
    if (o.status === 'ai_draft') return ['Sit tight — a developer is checking your AI quote.', 'Usually a few minutes. You can already ask questions in the chat on the right.', 'wait'];
    if (!o.paid) return ['Review your bill, then pay.', 'Switch optional items off to save money and ask anything in the chat — the developer can update prices live. When you’re happy, press “Accept & pay”.', 'you'];
    if (o.stage === 0) return ['Payment received. A developer will accept your order shortly.', 'You don’t need to do anything — this page updates by itself.', 'wait'];
    if (o.stage === 1) return ['Your developer accepted the order.', 'They’re about to start coding. Every step will appear in the tracker automatically.', 'wait'];
    if (o.stage === 2 && o.ciFailed) return ['Automated tests failed — the developer is fixing it.', 'Nothing for you to do. It moves on as soon as the tests pass.', 'wait'];
    if (o.stage === 2) return ['Your software is being built.', 'Every push is audited against your contract — watch items unlock in the Proof Vault below. Want something extra? Ask in the chat.', 'wait'];
    if (o.stage === 3) return ['Automated tests passed.', 'Next, the developer packages the work for review.', 'wait'];
    if (o.stage === 4) return ['Your order is ready for review.', 'A preview link will appear in the tracker so you can try it.', 'wait'];
    if (o.stage === 5) return ['Try it out!', 'Open the preview link in the tracker and tell the developer what you think in the chat.', 'you'];
    if (o.stage === 6) return ['Delivered — please confirm.', 'Check the work, then press “Accept delivery”.', 'you'];
    return ['All done. Thanks for ordering!', 'This order is complete. Start a new project any time.', 'done'];
  }
  if (o.status === 'ai_draft') return ['Review the AI quote and send it.', 'Adjust names, prices or optional items, then press “Approve & send to client”.', 'you'];
  if (!o.paid) return ['Negotiate with the client.', 'Edit prices and press “Push revision” — the client sees it instantly. The order moves to you once they pay.', 'wait'];
  if (o.stage === 0) return ['New paid order — accept it.', 'Optionally connect the GitHub repo first, then press “Accept order”.', 'you'];
  if (o.stage === 1)
    return o.repoFullName
      ? ['Start coding on the order branch.', `Create and push ${branch} in ${o.repoFullName} — the tracker moves to Cooking by itself.`, 'you']
      : ['Connect a GitHub repo.', 'Paste your repo link in Build controls so the client’s tracker updates automatically, then push the branch.', 'you'];
  if (o.stage === 2 && o.ciFailed) return ['CI failed — push a fix.', 'The tracker turns green again when the tests pass.', 'you'];
  if (o.stage === 2 && o.repoSync?.noCi)
    return ['Open a pull request when the code is ready.', `No CI was found in ${o.repoFullName}, so Quality check will be skipped. Add a GitHub Actions workflow (see demo-repo-template) to show it.`, 'you'];
  if (o.stage === 2) return ['Get CI green and prove each module.', 'When tests pass the order moves to Quality check. Each module’s escrow is paid out as soon as the auditor proves it in your code.', 'you'];
  if (o.stage === 3) return ['Open a pull request.', `Open a PR from ${branch} — the order moves to Out for delivery.`, 'you'];
  if (o.stage === 4) return ['Share a preview.', 'Deploy a preview (Vercel/Netlify) or paste a preview URL in Build controls.', 'you'];
  if (o.stage === 5) return ['Merge when the client is happy.', 'Merging the PR marks the order Delivered.', 'you'];
  if (o.stage === 6) return ['Waiting for the client to accept delivery.', o.autoAcceptAt ? 'If they don’t respond, it completes automatically.' : 'Nothing to do right now.', 'wait'];
  return ['Order complete.', 'Nice work.', 'done'];
}

export function NextStep({ order, role }) {
  const s = nextStep(order, role);
  if (!s) return null;
  const [title, body, who] = s;
  const tone =
    who === 'you'
      ? ['border-brand-500/50 bg-brand-50', 'bg-brand-500 text-white', 'Your move']
      : who === 'done'
        ? ['border-leaf/40 bg-leaf/10', 'bg-leaf text-paper', 'Complete']
        : ['border-stone-200 bg-surface', 'bg-stone-200 text-ink', 'In progress'];
  return (
    <div role="status" className={`slide-in mb-8 flex items-start gap-4 rounded-xl border p-5 ${tone[0]}`}>
      <span className={`mt-0.5 grid h-9 w-9 shrink-0 place-items-center rounded-full font-mono text-sm ${tone[1]}`}>
        {who === 'you' ? '→' : who === 'done' ? '✓' : <span className="h-2 w-2 animate-pulse rounded-full bg-ink" />}
      </span>
      <div className="min-w-0">
        <p className="font-mono text-[11px] uppercase tracking-[0.16em] text-stone-500">What happens next · {tone[2]}</p>
        <p className="mt-1 text-[18px] font-medium text-ink">{title}</p>
        <p className="mt-1 max-w-2xl text-sm leading-relaxed text-stone-500">{body}</p>
      </div>
    </div>
  );
}

/* ---------------------------------------------------------------------------------- OrderRow */
export function OrderRow({ order: o, to, meta, flash }) {
  return (
    <Link
      to={to}
      className={`group grid grid-cols-[90px_minmax(0,1fr)_auto] items-baseline gap-6 border-b border-stone-200 py-6 transition-colors md:grid-cols-[90px_minmax(0,1fr)_170px_120px_24px] ${flash ? 'flash' : ''}`}
    >
      <span className="font-mono text-xs text-stone-400">{o.id}</span>
      <span className="min-w-0">
        <span className="block truncate font-display text-[30px] leading-tight transition group-hover:italic">{o.title}</span>
        <span className="mt-1 block truncate font-mono text-[11px] text-stone-500">{meta}</span>
      </span>
      <span className="hidden md:block"><StatusBadge order={o} /></span>
      <span className="text-right font-mono text-base">{money(o.totalCents)}</span>
      <span className="hidden text-right text-stone-400 transition group-hover:translate-x-1 group-hover:text-ink md:block">→</span>
    </Link>
  );
}

/* --------------------------------------------------------------------------- WorkspaceHeader */
export function WorkspaceHeader({ back, order, amount, extra, onOpenModify }) {
  return (
    <div className="mb-8 border-b border-white/10 pb-6">
      <div className="flex items-center gap-4 font-mono text-[11px] uppercase tracking-[0.16em] text-stone-400">
        <Link to={back[0]} className="transition hover:text-white flex items-center gap-1.5">
          <span>←</span> <span>{back[1]}</span>
        </Link>
        <span className="text-white/20">/</span>
        <span className="text-stone-300">№ {order.id}</span>
        <span className="ml-auto flex items-center gap-3">
          {onOpenModify && order.stage <= 5 && (
            <button
              onClick={onOpenModify}
              className="inline-flex items-center gap-1.5 rounded-full border border-brand-500/40 bg-brand-500/10 px-3.5 py-1 font-mono text-[10px] uppercase tracking-wider text-brand-300 transition hover:bg-brand-500 hover:text-white"
            >
              <span>✏️</span> {order.paid ? 'Add to build' : 'Modify items & scope'}
            </button>
          )}
          <StatusBadge order={order} />
        </span>
      </div>
      <div className="mt-4 flex flex-wrap items-end justify-between gap-6">
        <div className="min-w-0">
          <h1 className="display text-[clamp(38px,4.5vw,72px)] text-white">{order.title}</h1>
          {extra && <p className="mt-2 text-sm text-stone-400">{extra}</p>}
        </div>
        <div className="text-right">
          <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-stone-400">Total bill</p>
          <span className="font-display text-5xl leading-none tracking-tight tabular-nums text-white">{amount}</span>
        </div>
      </div>
    </div>
  );
}

/* ----------------------------------------------------------------------------------- Tracker */
export function LiveTracker({ order }) {
  const current = order.stage;
  const pct = Math.round((Math.min(current, 7) / 7) * 100);
  return (
    <div className="card overflow-hidden border border-white/10 bg-[#0f111a] shadow-2xl">
      <div className="border-b border-white/10 px-6 pb-5 pt-6 bg-gradient-to-b from-white/[0.03] to-transparent">
        <div className="flex items-start justify-between gap-6">
          <div>
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-brand-500 animate-pulse" />
              <p className="eyebrow text-brand-400 font-semibold">Live Build Pipeline</p>
            </div>
            <p className="display mt-2 text-[44px] text-white">
              {order.ciFailed ? (
                <em className="italic text-brand-500">Back in the kitchen (CI failed)</em>
              ) : (
                <em className="italic">{STAGES[current]?.label}</em>
              )}
            </p>
          </div>
          <div className="text-right font-mono text-[11px] text-stone-400">
            <span className="block text-4xl font-normal text-white">{pct}%</span>
            <span className="uppercase tracking-[0.16em] text-brand-400 font-medium">stage {current} / 7</span>
          </div>
        </div>

        {/* Cyber-pipeline energy bar */}
        <div className="mt-5 flex gap-1.5 p-1 rounded-full bg-black/40 border border-white/5">
          {STAGES.slice(1).map((_, i) => (
            <span
              key={i}
              className={`h-2 flex-1 rounded-full transition-all duration-700 ${
                i + 1 < current || (i + 1 === current && current === 7)
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-400 shadow-sm shadow-emerald-500/50'
                  : i + 1 === current
                    ? order.ciFailed
                      ? 'bg-brand-500 shadow-md shadow-brand-500/60'
                      : 'pulse-ring bg-gradient-to-r from-brand-500 to-amber-500 shadow-md shadow-brand-500/50'
                    : 'bg-white/5'
              }`}
            />
          ))}
        </div>

        <div className="mt-4 flex flex-wrap items-center justify-between gap-2 font-mono text-[11px] text-stone-400">
          <p>
            Tracking branch <span className="text-brand-300 font-medium px-2 py-0.5 rounded bg-white/5 border border-white/10">{order.branchName}</span>
            {order.repoFullName && (
              <>
                {' '}in{' '}
                <a className="text-white underline decoration-stone-600 underline-offset-2 hover:decoration-brand-400" href={`https://github.com/${order.repoFullName}`} target="_blank" rel="noreferrer">
                  {order.repoFullName}
                </a>
                <span className="ml-2 inline-flex items-center gap-1 text-emerald-400 font-medium">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" /> synced
                </span>
              </>
            )}
          </p>
          <span className="font-mono text-[10px] text-stone-500">SHA-256: {order.scopeHash?.slice(0, 10)}…</span>
        </div>
      </div>

      <ol className="divide-y divide-white/5 px-6 py-2">
        {STAGES.map((s, i) => {
          const done = i < current || (i === current && current === 7);
          const active = i === current && current !== 7;
          const failed = active && order.ciFailed;
          const at = order.timeline?.[i];
          return (
            <li key={i} className={`flex items-baseline gap-5 py-3.5 transition-opacity ${i > current ? 'opacity-35' : ''}`}>
              <span className={`w-6 font-mono text-[11px] font-semibold ${active ? 'text-brand-400' : done ? 'text-emerald-400' : 'text-stone-600'}`}>
                {s.icon}
              </span>
              <span className="min-w-0 flex-1">
                <span className="flex items-baseline gap-3">
                  <span className={`font-display text-[22px] leading-none text-white ${active ? 'italic text-brand-300' : ''} ${failed ? '!text-brand-500' : ''}`}>
                    {s.label}
                  </span>
                  {active && !failed && <span className="h-2 w-2 animate-pulse rounded-full bg-brand-400" />}
                  {failed && <span className="font-mono text-[10px] uppercase tracking-[0.14em] text-brand-500 font-semibold">CI failed — fixing</span>}
                </span>
                <span className="mt-1 block text-xs text-stone-400">{s.desc}</span>
                {i === 4 && order.prUrl && current >= 4 && (
                  <a className="mt-2 inline-flex items-center gap-1 font-mono text-[11px] text-brand-400 hover:text-brand-300 underline underline-offset-2" href={order.prUrl} target="_blank" rel="noreferrer">
                    <span>View GitHub Pull Request</span> <span>↗</span>
                  </a>
                )}
                {i === 5 && order.previewUrl && current >= 5 && (
                  <a className="btn-accent mt-2 px-4 py-1.5 text-xs inline-flex items-center gap-1.5" href={order.previewUrl} target="_blank" rel="noreferrer">
                    <span>Open live preview</span> <span>↗</span>
                  </a>
                )}
              </span>
              <span className="font-mono text-[11px] text-stone-500">{done || active ? (at ? clock(at) : '') : ''}</span>
              <span className={`w-5 text-right font-mono text-xs ${done ? 'text-emerald-400 font-bold' : 'text-transparent'}`}>✓</span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}

/* -------------------------------------------------------------------------------------- Brief */
function BriefList({ title, items, mark, tone }) {
  if (!items?.length) return null;
  return (
    <div>
      <p className="label">{title}</p>
      <ul className="space-y-1.5 text-sm">
        {items.map((x, i) => (
          <li key={i} className="flex gap-3">
            <span className={`font-mono text-xs leading-5 ${tone}`}>{mark}</span>
            <span className="text-stone-300">{x}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function Brief({ brief }) {
  if (!brief) return null;
  return (
    <div className="card space-y-6 p-6">
      <div>
        <p className="eyebrow">The brief</p>
        <h3 className="display mt-2 text-4xl text-white">{brief.title}</h3>
        <p className="mt-3 text-[15px] leading-relaxed text-stone-400">{brief.summary}</p>
        <div className="mt-4 flex flex-wrap gap-x-5 gap-y-1 font-mono text-[11px] uppercase tracking-[0.12em] text-brand-400">
          {brief.timeline_days && <span>{brief.timeline_days} days delivery</span>}
          {brief.platforms?.map((p) => <span key={p}>{p}</span>)}
        </div>
      </div>
      <div className="grid gap-6 md:grid-cols-2">
        <BriefList title="In scope" items={brief.in_scope} mark="+" tone="text-emerald-400" />
        <BriefList title="Out of scope" items={brief.out_of_scope} mark="−" tone="text-brand-500" />
      </div>
      {brief.assumptions?.length > 0 && <BriefList title="Assumptions" items={brief.assumptions} mark="·" tone="text-stone-500" />}
    </div>
  );
}

/* -------------------------------------------------------------------------------- ToggleQuote */
export function ToggleQuote({ order, onToggle, onPay, busy, flashKey, onOpenModify }) {
  const q = order.quote;
  const total = totalOf(q.modules);
  const [flash, setFlash] = useState(false);
  useEffect(() => {
    if (!flashKey) return;
    setFlash(true);
    const t = setTimeout(() => setFlash(false), 1500);
    return () => clearTimeout(t);
  }, [flashKey]);

  return (
    <div className={`ticket px-7 pb-9 pt-9 ${flash ? 'flash' : ''}`}>
      <div className="flex items-end justify-between gap-4">
        <div>
          <p className="eyebrow">Quote · v{q.version}</p>
          <p className="display mt-2 text-5xl text-white">
            Your <em className="italic text-brand-400">bill</em>
          </p>
        </div>
        <div className="flex items-center gap-3">
          {onOpenModify && (
            <button
              onClick={onOpenModify}
              className="rounded-full border border-white/10 bg-white/5 px-3 py-1 font-mono text-[11px] text-brand-300 hover:border-brand-500/40 hover:bg-brand-500/10 transition"
            >
              ✏️ Modify items
            </button>
          )}
          {flash ? (
            <span className="slide-in rounded-full bg-brand-500 px-3 py-1 font-mono text-[10px] uppercase tracking-[0.14em] text-white">Revised live</span>
          ) : (
            <span className="font-mono text-[11px] text-stone-400">№ {order.id}</span>
          )}
        </div>
      </div>
      <p className="mt-3 text-sm text-stone-400">Switch optional items on or off, or click Modify to add dishes and custom requests.</p>
      <div className="rule-dashed my-5" />
      <ul className="space-y-1">
        {q.modules.map((m) => {
          const on = m.included || !m.optional;
          return (
            <li key={m.id} className={`flex items-start gap-4 py-2.5 transition-opacity duration-500 ${on ? '' : 'opacity-40'}`}>
              {m.optional ? (
                <button
                  disabled={busy}
                  onClick={() => onToggle(m.id, !m.included)}
                  className={`mt-0.5 h-5 w-9 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-300 ${on ? 'bg-brand-500' : 'bg-white/15'}`}
                  title="Toggle module"
                  aria-label={`${on ? 'Remove' : 'Add'} ${m.name}`}
                >
                  <span className={`block h-4 w-4 rounded-full bg-white transition-transform duration-300 ${on ? 'translate-x-4' : ''}`} />
                </button>
              ) : (
                <span className="mt-0.5 grid h-5 w-9 shrink-0 place-items-center font-mono text-xs text-emerald-400" title="Included">✓</span>
              )}
              <div className="min-w-0 flex-1">
                <div className="flex items-baseline gap-2">
                  <span className={`text-[15px] text-white ${on ? '' : 'line-through decoration-stone-500'}`}>{m.name}</span>
                  {m.menu && <span className="font-mono text-[9px] uppercase tracking-[0.14em] text-brand-400">menu</span>}
                  {!m.menu && !m.optional && <span className="font-mono text-[9px] uppercase tracking-[0.14em] text-stone-500">core</span>}
                  <span className="leader" />
                  <span className="font-mono text-[14px] text-white">{money(m.price_cents)}</span>
                </div>
                <p className="mt-0.5 text-xs leading-relaxed text-stone-400">{m.description}</p>
              </div>
            </li>
          );
        })}
      </ul>
      <div className="rule-dashed my-5" />
      <div className="flex items-end justify-between gap-6">
        <div>
          <p className="font-mono text-[11px] uppercase tracking-[0.16em] text-stone-400">Total due</p>
          <p className="font-display text-6xl leading-none tracking-tight tabular-nums text-white">{money(total)}</p>
        </div>
        <button className="btn-primary px-7 py-4 text-base" disabled={busy} onClick={onPay}>
          {busy ? 'Opening Stripe…' : 'Accept & pay'} <span aria-hidden>→</span>
        </button>
      </div>
      <div className="mt-5 flex items-start gap-3 rounded-xl border border-leaf/25 bg-leaf/[0.06] p-4">
        <span className="mt-0.5 font-mono text-sm text-leaf">⛨</span>
        <p className="text-[13px] leading-relaxed text-stone-500">
          <b className="font-medium text-ink">Pay for proof, not promises.</b> Your money waits in escrow. Each item is paid to the developer
          only after our AI auditor finds it working in the actual code, with the exact file and line as evidence. Anything never proven is refunded to you.
        </p>
      </div>
    </div>
  );
}


/* --------------------------------------------------------------------------- NegotiationChat */
export function NegotiationChat({ room, me, onAddonPay, onAddonSkip, onCreateAddon, busyAddon }) {
  const { messages, send, typing, typingPing, checking, order } = room;
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [err, setErr] = useState('');
  const endRef = useRef(null);
  const lastPing = useRef(0);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length, typing]);

  const submit = async (e) => {
    e.preventDefault();
    if (!text.trim()) return;
    setSending(true);
    setErr('');
    try {
      await send(text.trim());
      setText('');
    } catch (e2) {
      setErr(e2.message);
    } finally {
      setSending(false);
    }
  };

  const locked = order?.paid && order.stage <= 5;
  return (
    <div className="card flex h-full min-h-[520px] flex-col">
      <div className="flex items-center justify-between border-b border-stone-200 px-5 py-4">
        <div>
          <p className="font-display text-2xl leading-none">
            {me.role === 'client' ? order?.devName || 'Your developer' : order?.clientName}
          </p>
          <p className="mt-1 font-mono text-[10px] uppercase tracking-[0.14em] text-stone-500">
            {me.role === 'client' ? 'Developer' : 'Client'}
            {locked && me.role === 'dev' && ' · ScopeGuard watching'}
          </p>
        </div>
        {locked && (
          <span className="rounded-full border border-ink px-2.5 py-1 font-mono text-[10px] uppercase tracking-[0.14em]">Scope locked</span>
        )}
      </div>
      <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-5 py-5">
        {messages.length === 0 && (
          <div className="py-16 text-center">
            <p className="font-display text-2xl italic text-stone-500">Say hello.</p>
            <p className="mt-1 text-sm text-stone-400">Messages go straight to the {me.role === 'client' ? 'developer' : 'client'}, in real time.</p>
          </div>
        )}
        {messages.map((m) => (
          <Message
            key={m.id}
            m={m}
            me={me}
            checking={checking[m.id]}
            onAddonPay={onAddonPay}
            onAddonSkip={onAddonSkip}
            onCreateAddon={onCreateAddon}
            busyAddon={busyAddon}
          />
        ))}
        {typing && <p className="font-mono text-[11px] text-stone-400">{typing.name} is typing…</p>}
        <div ref={endRef} />
      </div>
      <form onSubmit={submit} className="border-t border-stone-200 p-3">
        {err && <p className="mb-2 px-2 font-mono text-[11px] text-brand-600">{err}</p>}
        <div className="flex items-center gap-2">
          <input
            className="w-full border-0 bg-transparent px-2 py-2 text-[15px] outline-none placeholder:text-stone-400"
            placeholder={me.role === 'client' ? 'Ask a question or request a change…' : 'Reply to the client…'}
            value={text}
            onChange={(e) => {
              setText(e.target.value);
              if (Date.now() - lastPing.current > 1500) {
                lastPing.current = Date.now();
                typingPing();
              }
            }}
          />
          <button className="btn-primary px-4 py-2" disabled={sending || !text.trim()} aria-label="Send">
            Send
          </button>
        </div>
      </form>
    </div>
  );
}

function Message({ m, me, checking, onAddonPay, onAddonSkip, onCreateAddon, busyAddon }) {
  if (m.senderRole === 'system') {
    return (
      <div className="slide-in flex items-center gap-3 py-1">
        <span className="h-px flex-1 bg-stone-200" />
        <span className="max-w-[80%] text-center font-mono text-[11px] leading-relaxed text-stone-500">{m.content}</span>
        <span className="h-px flex-1 bg-stone-200" />
      </div>
    );
  }
  const mine = m.senderId === me.id;
  const sc = m.metadata?.scopeCheck;

  if (m.type === 'scope_addon') return <AddonCard m={m} me={me} onPay={onAddonPay} onSkip={onAddonSkip} busy={busyAddon} />;

  return (
    <div className={`slide-in flex ${mine ? 'justify-end' : 'justify-start'}`}>
      <div className="max-w-[82%]">
        <div
          className={`rounded-2xl px-4 py-2.5 text-[14.5px] leading-relaxed ${
            mine ? 'rounded-br-md bg-ink text-paper' : 'rounded-bl-md border border-stone-200 bg-paper text-ink'
          } ${m.scopeFlagged && me.role === 'dev' ? 'ring-2 ring-brand-500 ring-offset-2 ring-offset-surface' : ''}`}
        >
          {m.type === 'quote_revision' && (
            <p className={`mb-1 font-mono text-[10px] uppercase tracking-[0.14em] ${mine ? 'text-stone-400' : 'text-brand-600'}`}>
              Quote v{m.metadata?.version} · {money(m.metadata?.totalCents)}
            </p>
          )}
          <p className="whitespace-pre-wrap break-words">{m.content}</p>
          {m.metadata?.changes?.length > 0 && (
            <ul className={`mt-1.5 space-y-0.5 font-mono text-[11px] ${mine ? 'text-stone-400' : 'text-stone-500'}`}>
              {m.metadata.changes.map((c, i) => <li key={i}>— {c}</li>)}
            </ul>
          )}
        </div>
        <p className={`mt-1 font-mono text-[10px] text-stone-400 ${mine ? 'text-right' : ''}`}>
          {!mine && `${m.senderName} · `}
          {clock(m.createdAt)}
        </p>
        {me.role === 'dev' && m.senderRole === 'client' && checking && (
          <p className="mt-1 font-mono text-[10px] uppercase tracking-[0.14em] text-stone-400">ScopeGuard checking…</p>
        )}
        {me.role === 'dev' && sc?.outOfScope && (
          <div className="slide-in mt-2 rounded-xl border border-brand-300 bg-brand-50 p-3">
            <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-brand-600">⚑ Potential scope change</p>
            <p className="mt-1 text-xs leading-relaxed text-stone-700">{sc.reason}</p>
            {sc.suggestion && (
              <button className="btn-primary mt-3 px-3.5 py-1.5 text-xs" onClick={() => onCreateAddon?.(sc.suggestion, m.id)}>
                Price it: {sc.suggestion.title} · {money(sc.suggestion.priceCents)} →
              </button>
            )}
          </div>
        )}
        {me.role === 'dev' && sc && !sc.outOfScope && (
          <p className="mt-1 font-mono text-[10px] uppercase tracking-[0.14em] text-leaf">✓ In scope</p>
        )}
      </div>
    </div>
  );
}

function AddonCard({ m, me, onPay, onSkip, busy }) {
  const meta = m.metadata || {};
  const status = meta.status;
  return (
    <div className="slide-in ticket mx-auto w-full max-w-sm px-6 pb-7 pt-8 [background:var(--color-paper)]">
      <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-brand-600">Add to order</p>
      <div className="mt-2 flex items-baseline gap-2">
        <span className="font-display text-2xl leading-tight">{meta.title}</span>
        <span className="leader" />
        <span className="font-mono text-lg">{money(meta.priceCents)}</span>
      </div>
      {meta.description && <p className="mt-1 text-xs text-stone-500">{meta.description}</p>}
      <p className="mt-3 text-[13px] leading-relaxed text-stone-600">{m.content}</p>
      {status === 'offered' && me.role === 'client' && (
        <div className="mt-4 grid grid-cols-2 gap-2">
          <button className="btn-ghost py-2" disabled={busy} onClick={() => onSkip(m.id)}>Skip</button>
          <button className="btn-primary py-2" disabled={busy} onClick={() => onPay(m.id)}>Pay & add</button>
        </div>
      )}
      {status === 'offered' && me.role === 'dev' && <p className="mt-4 font-mono text-[10px] uppercase tracking-[0.14em] text-stone-400">Waiting for client…</p>}
      {status === 'paid' && <p className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-leaf">✓ Paid · added to scope</p>}
      {status === 'skipped' && <p className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-stone-400">Skipped · scope unchanged</p>}
    </div>
  );
}
