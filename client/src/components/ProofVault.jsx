import { useEffect, useState } from 'react';
import { api, money, timeAgo } from '../lib/api.js';

const STATUS = {
  proven: { icon: '✓', label: 'Proven', dot: 'bg-leaf', text: 'text-leaf' },
  partial: { icon: '◐', label: 'In progress', dot: 'bg-amber-400', text: 'text-amber-300' },
  missing: { icon: '○', label: 'Not found', dot: 'bg-stone-400', text: 'text-stone-400' },
  pending: { icon: '·', label: 'Not audited', dot: 'bg-stone-300', text: 'text-stone-400' },
};

/** Proof-of-Delivery escrow: per-module money that only moves when the code proves the contract. */
export function ProofVault({ order, role }) {
  const proof = order.proof || {};
  const modules = (order.quote?.modules || []).filter((m) => m.included || !m.optional);
  const audit = proof.audit;
  const busy = proof.status === 'compiling' || proof.status === 'auditing';
  const [open, setOpen] = useState(null);
  const [err, setErr] = useState('');
  const [asking, setAsking] = useState(false);

  const total = modules.reduce((s, m) => s + m.price_cents, 0);
  const released = modules.reduce((s, m) => s + (proof.escrow?.[m.id]?.state === 'released' ? m.price_cents : 0), 0);
  const held = total - released;
  const done = order.stage === 7;
  const allCriteria = modules.flatMap((m) => proof.criteria?.[m.id] || []);
  const provenCount = audit ? allCriteria.filter((c) => audit.results?.[c.id]?.status === 'proven').length : 0;

  const runAudit = async () => {
    setAsking(true);
    setErr('');
    try {
      await api(`/api/orders/${order.id}/proof/audit`, { method: 'POST' });
    } catch (e) {
      setErr(e.message);
    } finally {
      setAsking(false);
    }
  };

  return (
    <section className="card overflow-hidden" aria-label="Proof-of-Delivery escrow">
      {/* Header + ledger */}
      <div className="relative p-6">
        <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-leaf/60 to-transparent" />
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="eyebrow">Proof-of-Delivery escrow</p>
            <h3 className="display mt-2 text-4xl text-ink">
              Paid on <em className="italic text-leaf">proof</em>, not promises
            </h3>
            <p className="mt-2 max-w-xl text-sm leading-relaxed text-stone-500">
              {role === 'client'
                ? 'Your payment sits in escrow. An AI auditor reads every commit and releases each item to the developer only when it finds the feature in the code.'
                : 'Each module pays out the moment the auditor proves it in your repo. Push code — the audit runs on every new commit.'}
            </p>
          </div>
          <div className="flex flex-col items-end gap-2">
            <button className="btn-ghost text-xs" onClick={runAudit} disabled={busy || asking || !order.repoFullName}>
              {busy ? 'Auditing…' : asking ? 'Starting…' : '↻ Audit latest commit'}
            </button>
            {proof.criteriaHash && (
              <span className="font-mono text-[10px] text-stone-400" title={proof.criteriaHash}>
                contract {proof.criteriaHash.slice(0, 10)}…
              </span>
            )}
          </div>
        </div>

        {/* Ledger bar */}
        <div className="mt-6">
          <div className="flex h-3 overflow-hidden rounded-full bg-white/[0.06]">
            <div className="h-full bg-gradient-to-r from-emerald-500 to-leaf transition-all duration-1000" style={{ width: `${total ? (released / total) * 100 : 0}%` }} />
            <div
              className={`h-full transition-all duration-1000 ${done ? 'bg-sky-400/60' : 'bg-[repeating-linear-gradient(135deg,rgba(251,191,36,.55)_0_6px,rgba(251,191,36,.25)_6px_12px)]'}`}
              style={{ width: `${total ? (held / total) * 100 : 0}%` }}
            />
          </div>
          <div className="mt-3 grid grid-cols-3 gap-4 font-mono text-xs">
            <Stat label="Released to developer" value={money(released)} tone="text-leaf" />
            <Stat label={done ? 'Refund due to client' : 'Held in escrow'} value={money(held)} tone={done ? 'text-sky-300' : 'text-amber-300'} />
            <Stat label="Criteria proven" value={audit ? `${provenCount}/${allCriteria.length}` : `0/${allCriteria.length || '–'}`} tone="text-ink" />
          </div>
        </div>

        {/* Audit status line */}
        <div className="mt-5 rounded-xl border border-white/[0.06] bg-black/30 px-4 py-3 font-mono text-[11px] text-stone-500">
          {busy ? (
            <span className="flex items-center gap-2 text-cyan">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-cyan opacity-70" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-cyan" />
              </span>
              {proof.progress || 'Working…'}
            </span>
          ) : proof.status === 'error' ? (
            <span className="text-brand-600">Audit failed: {proof.error}</span>
          ) : audit ? (
            <span>
              Last audit{' '}
              <a className="text-ink underline-offset-2 hover:underline" href={`https://github.com/${order.repoFullName}/commit/${audit.sha}`} target="_blank" rel="noreferrer">
                {audit.sha.slice(0, 7)}
              </a>{' '}
              · {timeAgo(audit.at)} · read {audit.filesRead} of {audit.filesInRepo} source files
              {audit.changedFiles ? ` · ${audit.changedFiles} changed on the branch` : ''}
            </span>
          ) : !order.repoFullName ? (
            <span>{role === 'client' ? 'Audits start as soon as your developer connects the GitHub repo.' : 'Connect the GitHub repo in Build controls — every push will be audited.'}</span>
          ) : (
            <span>Waiting for the first commit on {order.branchName}…</span>
          )}
        </div>
        {audit?.summary && !busy && <p className="mt-3 text-sm leading-relaxed text-stone-500">{audit.summary}</p>}
        {err && <p className="mt-2 text-xs text-brand-600">{err}</p>}
      </div>

      {/* Modules */}
      <ul className="divide-y divide-white/[0.06] border-t border-white/[0.06]">
        {modules.map((m) => {
          const crit = proof.criteria?.[m.id] || [];
          const esc = proof.escrow?.[m.id];
          const isReleased = esc?.state === 'released';
          const n = crit.filter((c) => audit?.results?.[c.id]?.status === 'proven').length;
          const expanded = open === m.id;
          return (
            <li key={m.id}>
              <button className="flex w-full items-center gap-4 px-6 py-4 text-left transition hover:bg-white/[0.02]" onClick={() => setOpen(expanded ? null : m.id)} aria-expanded={expanded}>
                <span className={`grid h-9 w-9 shrink-0 place-items-center rounded-full border font-mono text-sm ${isReleased ? 'border-leaf/40 bg-leaf/15 text-leaf' : 'border-amber-400/30 bg-amber-400/10 text-amber-300'}`}>
                  {isReleased ? '✓' : '⛨'}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="flex items-baseline gap-2">
                    <span className="truncate text-[15px] text-ink">{m.name}</span>
                    <span className="leader" />
                    <span className="font-mono text-sm text-ink">{money(m.price_cents)}</span>
                  </span>
                  <span className="mt-1 flex items-center gap-3 font-mono text-[10px] uppercase tracking-[0.14em]">
                    <span className={isReleased ? 'text-leaf' : done ? 'text-sky-300' : esc?.blockedByCi ? 'text-brand-600' : 'text-amber-300'}>
                      {isReleased ? `Released ${timeAgo(esc.releasedAt)}` : done ? 'Unproven · refund due' : esc?.blockedByCi ? 'Proven · waiting for CI' : 'Held'}
                    </span>
                    <span className="text-stone-400">{crit.length ? `${n}/${crit.length} proven` : busy ? 'compiling criteria…' : 'criteria pending'}</span>
                    <span className="flex gap-1">
                      {crit.map((c) => (
                        <span key={c.id} className={`h-1.5 w-4 rounded-full ${STATUS[audit?.results?.[c.id]?.status || 'pending'].dot}`} />
                      ))}
                    </span>
                  </span>
                </span>
                <span className={`text-stone-400 transition ${expanded ? 'rotate-90' : ''}`}>›</span>
              </button>

              {expanded && (
                <div className="slide-in space-y-3 px-6 pb-6">
                  {!crit.length && <p className="text-sm text-stone-500">Acceptance criteria are compiled from the contract right after payment.</p>}
                  {crit.map((c) => {
                    const r = audit?.results?.[c.id];
                    const st = STATUS[r?.status || 'pending'];
                    return (
                      <div key={c.id} className="rounded-xl border border-white/[0.06] bg-black/25 p-4">
                        <div className="flex items-start gap-3">
                          <span className={`mt-0.5 font-mono text-sm ${st.text}`}>{st.icon}</span>
                          <div className="min-w-0 flex-1">
                            <p className="text-sm text-ink">{c.text}</p>
                            <p className={`mt-1 font-mono text-[10px] uppercase tracking-[0.14em] ${st.text}`}>{st.label}</p>
                            {r?.note && <p className="mt-2 text-[13px] leading-relaxed text-stone-500">{r.note}</p>}
                            {role === 'dev' && r?.status !== 'proven' && c.look_for && (
                              <p className="mt-2 text-[12px] text-stone-400">
                                <span className="font-mono text-[10px] uppercase tracking-[0.14em] text-brand-400">To prove · </span>
                                {c.look_for}
                              </p>
                            )}
                            {r?.evidence && <Evidence ev={r.evidence} />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {isReleased && (
                    <p className="font-mono text-[10px] text-stone-400">
                      escrow tx {esc.txId} · commit {esc.sha?.slice(0, 7)}
                    </p>
                  )}
                </div>
              )}
            </li>
          );
        })}
      </ul>
    </section>
  );
}

function Stat({ label, value, tone }) {
  return (
    <div>
      <p className="text-[10px] uppercase tracking-[0.14em] text-stone-400">{label}</p>
      <p className={`mt-1 text-lg tabular-nums ${tone}`}>{value}</p>
    </div>
  );
}

function Evidence({ ev }) {
  const lines = ev.snippet.split('\n');
  return (
    <div className="mt-3 overflow-hidden rounded-lg border border-leaf/20">
      <a href={ev.url} target="_blank" rel="noreferrer" className="flex items-center justify-between bg-leaf/[0.07] px-3 py-1.5 font-mono text-[11px] text-leaf hover:bg-leaf/[0.12]">
        <span className="truncate">{ev.file}:{ev.lineStart}{ev.lineEnd > ev.lineStart ? `–${ev.lineEnd}` : ''}</span>
        <span>view on GitHub ↗</span>
      </a>
      <pre className="max-h-56 overflow-auto bg-black/50 p-3 font-mono text-[11px] leading-relaxed text-stone-600">
        {lines.map((l, i) => (
          <div key={i} className="flex">
            <span className="mr-3 w-8 shrink-0 select-none text-right text-stone-300">{ev.lineStart + i}</span>
            <span className="whitespace-pre">{l || ' '}</span>
          </div>
        ))}
      </pre>
    </div>
  );
}

/** Reputation computed from audited evidence (can't be bought with fake reviews). */
export function ProofScore({ devId, name, compact = false }) {
  const [s, setS] = useState(null);
  useEffect(() => {
    if (!devId) return;
    api(`/api/proof-score/${devId}`).then(setS).catch(() => {});
  }, [devId]);
  if (!devId || !s) return null;
  const score = s.score;
  const ring = score == null ? 0 : score;
  const R = 26;
  const C = 2 * Math.PI * R;
  return (
    <div className={`card flex items-center gap-5 ${compact ? 'p-4' : 'p-6'}`}>
      <svg width="68" height="68" viewBox="0 0 68 68" className="shrink-0" aria-hidden>
        <circle cx="34" cy="34" r={R} fill="none" stroke="rgba(255,255,255,.08)" strokeWidth="6" />
        <circle
          cx="34" cy="34" r={R} fill="none" stroke="var(--color-leaf)" strokeWidth="6" strokeLinecap="round"
          strokeDasharray={`${(ring / 100) * C} ${C}`} transform="rotate(-90 34 34)"
          style={{ transition: 'stroke-dasharray 1s var(--ease-out-expo)' }}
        />
        <text x="34" y="39" textAnchor="middle" className="fill-ink font-mono" fontSize="16">{score ?? '–'}</text>
      </svg>
      <div className="min-w-0">
        <p className="eyebrow">Proof Score{name ? ` · ${name}` : ''}</p>
        <p className="mt-1 text-sm text-ink">
          {score == null
            ? 'No audited work yet — the score builds from verified code, not reviews.'
            : `${s.proven} of ${s.criteria} contract criteria proven in code across ${s.audited} audited order${s.audited === 1 ? '' : 's'}.`}
        </p>
        <p className="mt-1 font-mono text-[11px] text-stone-400">
          {money(s.releasedCents)} earned on proof · {s.modulesReleased}/{s.modules} modules released · {s.audits} audits
        </p>
      </div>
    </div>
  );
}
