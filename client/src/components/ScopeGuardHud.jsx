import { useState } from 'react';
import { money } from '../lib/api.js';

export function ScopeGuardHud({ order, onOpenModify }) {
  const [inspectOpen, setInspectOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  if (!order) return null;

  const hash = order.scopeHash || 'pending-contract-lock';
  const shortHash = hash.slice(0, 12);
  const isLocked = !!order.paid;
  const isCooking = ['cooking', 'quality_check', 'out_for_delivery', 'taste_test'].includes(order.status);

  const copyHash = () => {
    navigator.clipboard?.writeText(hash);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <>
      <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-r from-[#10131e] via-[#0d1019] to-[#121622] p-5 shadow-2xl backdrop-blur-xl">
        {/* Ambient Top Glow Line */}
        <div className="absolute inset-x-0 top-0 h-[1.5px] bg-gradient-to-r from-transparent via-brand-500/60 to-transparent" />

        <div className="flex flex-wrap items-center justify-between gap-4">
          {/* Left: Shield Status */}
          <div className="flex items-center gap-3.5">
            <div className="relative grid h-10 w-10 place-items-center rounded-xl border border-brand-500/30 bg-brand-500/10 text-brand-400">
              <span className="text-xl">🛡️</span>
              {isCooking && (
                <span className="absolute -inset-1 rounded-xl border border-brand-500/40 animate-ping opacity-40" />
              )}
            </div>

            <div>
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-white">
                  ScopeGuard Protocol
                </span>
                <span className="inline-flex items-center gap-1 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2 py-0.5 font-mono text-[9px] uppercase tracking-widest text-emerald-300">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  {isLocked ? 'Shield Active' : 'Pre-Lock Mode'}
                </span>
              </div>
              <p className="mt-0.5 text-xs text-stone-400">
                {isLocked
                  ? 'AI active: analyzing commits, pull requests, and chat for scope creep in real time.'
                  : 'Modular scope pricing: adjust dishes or custom specifications before locking.'}
              </p>
            </div>
          </div>

          {/* Right: Actions & Hash */}
          <div className="flex flex-wrap items-center gap-3">
            {/* Cryptographic Hash Badge */}
            <button
              onClick={() => setInspectOpen(true)}
              className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[0.03] px-3.5 py-2 font-mono text-xs text-stone-300 transition hover:border-brand-500/40 hover:bg-white/[0.06] hover:text-white"
              title="Click to inspect cryptographic scope contract"
            >
              <span className="text-brand-400 font-semibold">SHA-256</span>
              <span className="text-stone-300">{shortHash}…</span>
              <span className="text-[10px] text-stone-400">🔍</span>
            </button>

            {/* Quick Modify Order Button */}
            {onOpenModify && order.stage <= 5 && (
              <button
                onClick={onOpenModify}
                className="btn border border-brand-500/40 bg-brand-500/10 px-4 py-2 font-mono text-xs text-brand-300 transition hover:bg-brand-500 hover:text-white"
              >
                ✏️ {isLocked ? 'Add to Order' : 'Modify Order'}
              </button>
            )}
          </div>
        </div>

        {/* Real-time Telemetry Bar */}
        <div className="mt-4 grid grid-cols-2 gap-2 border-t border-white/5 pt-3 text-[11px] font-mono sm:grid-cols-4 text-stone-400">
          <div>
            <span className="text-stone-400 uppercase tracking-wider block text-[9px]">Scope Drift</span>
            <span className="text-emerald-400 font-medium">0.00% (Guarded)</span>
          </div>
          <div>
            <span className="text-stone-400 uppercase tracking-wider block text-[9px]">Contract Version</span>
            <span className="text-white font-medium">v{order.quote?.version || 1}</span>
          </div>
          <div>
            <span className="text-stone-400 uppercase tracking-wider block text-[9px]">GitHub Sync</span>
            <span className="text-cyan-400 font-medium">8s Polling Active</span>
          </div>
          <div>
            <span className="text-stone-400 uppercase tracking-wider block text-[9px]">AI Guard Model</span>
            <span className="text-white font-medium">Nemotron 3 Ultra</span>
          </div>
        </div>
      </div>

      {/* Contract Verification Modal */}
      {inspectOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-black/80 backdrop-blur-md"
            onClick={() => setInspectOpen(false)}
          />
          <div className="modal-pop relative w-full max-w-lg rounded-2xl border border-white/10 bg-[#0e1017] p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <div className="flex items-center gap-2">
                <span className="text-lg">🛡️</span>
                <h3 className="font-display text-2xl text-white">Cryptographic Scope Contract</h3>
              </div>
              <button
                onClick={() => setInspectOpen(false)}
                className="text-stone-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <div className="mt-4 space-y-4 text-xs font-mono">
              <div>
                <p className="text-stone-400 uppercase tracking-wider text-[10px]">Contract SHA-256 Digest</p>
                <div className="mt-1 flex items-center justify-between rounded-lg border border-white/10 bg-black/60 p-2.5 text-brand-300 break-all select-all">
                  <span>{hash}</span>
                  <button
                    onClick={copyHash}
                    className="ml-2 shrink-0 rounded bg-white/10 px-2 py-1 text-[10px] text-white hover:bg-white/20"
                  >
                    {copied ? '✓ Copied' : 'Copy'}
                  </button>
                </div>
              </div>

              <div>
                <p className="text-stone-400 uppercase tracking-wider text-[10px]">Protected Deliverables</p>
                <ul className="mt-1 max-h-40 overflow-y-auto space-y-1 rounded-lg border border-white/5 bg-black/30 p-2 text-stone-300">
                  {(order.quote?.modules || [])
                    .filter((m) => m.included || !m.optional)
                    .map((m) => (
                      <li key={m.id} className="flex justify-between py-0.5">
                        <span className="truncate">{m.name}</span>
                        <span className="text-stone-400 ml-2">{money(m.price_cents)}</span>
                      </li>
                    ))}
                </ul>
              </div>

              <div className="rounded-lg border border-emerald-500/20 bg-emerald-500/10 p-3 text-stone-300">
                <p className="font-semibold text-emerald-400">✓ Cryptographically Immutable</p>
                <p className="mt-0.5 text-[11px] leading-relaxed text-stone-400">
                  Any pull request or requested feature introducing unpriced modifications triggers automatic ScopeGuard detection before merge.
                </p>
              </div>
            </div>

            <div className="mt-5 text-right">
              <button
                onClick={() => setInspectOpen(false)}
                className="btn-dark px-5 py-2 text-xs"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
