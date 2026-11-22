import { useEffect, useRef, useState } from 'react';
import { useParams, useSearchParams, Link } from 'react-router-dom';
import { api, money, totalOf } from '../../lib/api.js';
import { useOrderRoom } from '../../lib/useOrderRoom.js';
import { useAuth } from '../../context/AuthContext.jsx';
import { FullSpinner } from '../../components/Layout.jsx';
import { Brief, LiveTracker, NegotiationChat, ToggleQuote, WorkspaceHeader, NextStep } from '../../components/Order.jsx';
import { ScopeGuardHud } from '../../components/ScopeGuardHud.jsx';
import { ModifyOrderModal } from '../../components/ModifyOrderModal.jsx';
import { ProofVault, ProofScore } from '../../components/ProofVault.jsx';

function AutoAcceptCountdown({ at }) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);
  const ms = Math.max(0, new Date(at).getTime() - now);
  const d = Math.floor(ms / 86400e3);
  const h = Math.floor((ms % 86400e3) / 3600e3);
  const m = Math.floor((ms % 3600e3) / 60e3);
  const s = Math.floor((ms % 60e3) / 1000);
  const left = d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : `${m}m ${String(s).padStart(2, '0')}s`;
  return <p className="mt-3 font-mono text-[11px] uppercase tracking-[0.14em] text-stone-400">Auto-accepts in <span className="tabular-nums text-paper">{left}</span></p>;
}

export default function ClientOrderWorkspace() {
  const { id } = useParams();
  const { user } = useAuth();
  const room = useOrderRoom(id);
  const { order, setOrder, error, flashKey } = room;
  const [params, setParams] = useSearchParams();
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState(null);
  const [modifyOpen, setModifyOpen] = useState(false);
  const verified = useRef(false);

  // Returning from Stripe Checkout: confirm server-side with Stripe (independent of webhooks).
  useEffect(() => {
    const sessionId = params.get('session_id');
    if (params.get('canceled')) {
      setNotice({ tone: 'warn', text: 'Checkout canceled — nothing was charged.' });
      setParams({}, { replace: true });
    }
    if (!sessionId || verified.current) return;
    verified.current = true;
    setNotice({ tone: 'info', text: 'Confirming payment with Stripe…' });
    api('/api/payments/verify', { method: 'POST', body: { sessionId } })
      .then((d) => {
        if (d.order) setOrder(d.order);
        setNotice(d.settled ? { tone: 'ok', text: '✓ Payment confirmed. Your order is locked in.' } : { tone: 'warn', text: `Payment not completed (${d.reason}).` });
      })
      .catch((e) => setNotice({ tone: 'err', text: e.message }))
      .finally(() => setParams({}, { replace: true }));
  }, [params, setParams, setOrder]);

  if (error) return <p className="p-6 text-red-600">{error}</p>;
  if (!order) return <FullSpinner />;

  const toggle = async (moduleId, included) => {
    const modules = order.quote.modules.map((m) => (m.id === moduleId ? { ...m, included } : m));
    setOrder({ ...order, quote: { ...order.quote, modules }, totalCents: totalOf(modules) });
    try {
      const d = await api(`/api/orders/${order.id}/toggles`, { method: 'PATCH', body: { modules: [{ id: moduleId, included }] } });
      setOrder(d.order);
    } catch (e) {
      setNotice({ tone: 'err', text: e.message });
      room.reload();
    }
  };

  const pay = async () => {
    setBusy(true);
    try {
      const d = await api(`/api/orders/${order.id}/checkout`, { method: 'POST', body: { quoteVersion: order.quote.version } });
      window.location.href = d.checkoutUrl;
    } catch (e) {
      setNotice({ tone: 'err', text: e.message });
      setBusy(false);
    }
  };

  const payAddon = async (addonId) => {
    setBusy(true);
    try {
      const d = await api(`/api/orders/${order.id}/addons/${addonId}/pay`, { method: 'POST' });
      window.location.href = d.checkoutUrl;
    } catch (e) {
      setNotice({ tone: 'err', text: e.message });
      setBusy(false);
    }
  };
  const skipAddon = async (addonId) => {
    setBusy(true);
    try {
      await api(`/api/orders/${order.id}/addons/${addonId}/skip`, { method: 'POST' });
    } catch (e) {
      setNotice({ tone: 'err', text: e.message });
    } finally {
      setBusy(false);
    }
  };
  const acceptDelivery = async () => {
    setBusy(true);
    try {
      const d = await api(`/api/orders/${order.id}/client-accept`, { method: 'POST' });
      setOrder(d.order);
    } catch (e) {
      setNotice({ tone: 'err', text: e.message });
    } finally {
      setBusy(false);
    }
  };

  const NOTICE = { ok: 'border-emerald-500 text-emerald-400 bg-emerald-500/10', warn: 'border-amber-500 text-amber-300 bg-amber-500/10', err: 'border-brand-500 text-brand-300 bg-brand-500/10', info: 'border-cyan-500 text-cyan-300 bg-cyan-500/10' };

  return (
    <div className="mx-auto max-w-[1400px] px-6 pb-16 pt-8">
      <WorkspaceHeader
        back={['/client/orders', 'Orders']}
        order={order}
        amount={money(order.paid ? order.totalCents : totalOf(order.quote?.modules))}
        onOpenModify={() => setModifyOpen(true)}
      />

      {/* ScopeGuard High-Tech Defense HUD */}
      <div className="mb-6">
        <ScopeGuardHud order={order} onOpenModify={() => setModifyOpen(true)} />
      </div>

      <NextStep order={order} role="client" />

      {notice && (
        <div className={`slide-in mb-6 flex items-center justify-between rounded-xl border p-4 font-mono text-xs ${NOTICE[notice.tone]}`}>
          <span>{notice.text}</span>
          <button onClick={() => setNotice(null)} className="text-stone-400 hover:text-white" aria-label="Dismiss">×</button>
        </div>
      )}

      <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_430px]">
        <div className="space-y-8">
          {order.status === 'scoping' && (
            <div className="card p-8">
              <p className="display text-4xl text-white">This order was never <em className="italic text-brand-400">finished.</em></p>
              <Link className="btn-primary mt-6" to="/client/new">Start a new one →</Link>
            </div>
          )}
          {order.status === 'ai_draft' && (
            <>
              <div className="card flex items-center justify-between gap-6 p-8">
                <div className="flex items-center gap-5">
                  <span className="relative flex h-3.5 w-3.5">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-400 opacity-60" />
                    <span className="relative inline-flex h-3.5 w-3.5 rounded-full bg-brand-500" />
                  </span>
                  <div>
                    <p className="display text-4xl text-white">A developer is <em className="italic text-brand-400">reviewing</em> your quote</p>
                    <p className="mt-2 text-sm text-stone-400">
                      Draft total <span className="font-mono text-white font-semibold">{money(totalOf(order.quote.modules))}</span>. It appears here live the moment it’s approved.
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setModifyOpen(true)}
                  className="btn border border-white/10 bg-white/5 text-xs font-mono uppercase tracking-wider text-brand-300 hover:bg-white/10 shrink-0"
                >
                  ✏️ Edit items
                </button>
              </div>
              <Brief brief={order.quote.brief} />
            </>
          )}
          {!order.paid && ['negotiating', 'awaiting_payment'].includes(order.status) && (
            <>
              <ToggleQuote
                order={order}
                onToggle={toggle}
                onPay={pay}
                busy={busy}
                flashKey={flashKey}
                onOpenModify={() => setModifyOpen(true)}
              />
              <Brief brief={order.quote.brief} />
            </>
          )}
          {order.paid && (
            <>
              {order.stage === 6 && (
                <div className="slide-in flex flex-wrap items-center justify-between gap-6 rounded-2xl border border-emerald-500/30 bg-[#0f1715] p-8 shadow-2xl">
                  <div>
                    <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-emerald-400">Delivered</p>
                    <p className="display mt-2 text-5xl text-white">Your order is <em className="italic text-emerald-400">here.</em></p>
                    <p className="mt-2 text-sm text-stone-300">Review the merged work{order.previewUrl ? ' and the preview' : ''}, then accept delivery.</p>
                    {order.autoAcceptAt && <AutoAcceptCountdown at={order.autoAcceptAt} />}
                  </div>
                  <button className="btn bg-emerald-500 px-7 py-4 text-base font-semibold text-black hover:bg-emerald-400 shadow-lg shadow-emerald-500/30" disabled={busy} onClick={acceptDelivery}>
                    Accept delivery →
                  </button>
                </div>
              )}
              {order.stage === 7 && (
                <div className="slide-in rounded-2xl border border-white/10 bg-[#0f111a] p-8 shadow-2xl">
                  <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-emerald-400">Completed</p>
                  <p className="display mt-2 text-5xl text-white">Thanks for <em className="italic text-brand-400">dining</em> with us.</p>
                  <p className="mt-2 text-sm text-stone-400">Your software was built on time, on budget, and fully guarded against scope creep.</p>
                </div>
              )}
              <LiveTracker order={order} />
              <ProofVault order={order} role="client" />
              {order.devId && <ProofScore key={order.proof?.audit?.sha || 'none'} devId={order.devId} name={order.devName} compact />}

              {/* Locked Scope Card with Add-to-build CTA */}
              <div className="card p-6 border border-white/10">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="eyebrow text-stone-400">Locked scope · v{order.quote.version}</p>
                    <p className="font-display text-2xl text-white mt-1">Contract Deliverables</p>
                  </div>
                  {order.stage <= 5 && (
                    <button
                      onClick={() => setModifyOpen(true)}
                      className="btn border border-brand-500/40 bg-brand-500/10 px-4 py-2 text-xs font-mono text-brand-300 hover:bg-brand-500 hover:text-white"
                    >
                      + Add items to build
                    </button>
                  )}
                </div>

                <ul className="mt-5 space-y-3 text-[15px]">
                  {order.quote.modules.filter((m) => m.included || !m.optional).map((m) => (
                    <li key={m.id} className="flex items-baseline gap-2">
                      <span className="text-white font-medium">{m.name}</span>
                      {m.addon && <span className="font-mono text-[9px] uppercase tracking-[0.14em] text-brand-400 bg-brand-500/10 px-2 py-0.5 rounded-full">add-on</span>}
                      {m.menu && <span className="font-mono text-[9px] uppercase tracking-[0.14em] text-cyan-400 bg-cyan-500/10 px-2 py-0.5 rounded-full">menu</span>}
                      <span className="leader" />
                      <span className="font-mono text-sm text-white font-semibold">{money(m.price_cents)}</span>
                    </li>
                  ))}
                </ul>

                <div className="mt-5 flex items-center justify-between border-t border-white/5 pt-4 font-mono text-xs text-stone-400">
                  <span>SHA-256 Scope Integrity:</span>
                  <span className="text-emerald-400 font-semibold">{order.scopeHash?.slice(0, 16)}… (Verified)</span>
                </div>
              </div>
            </>
          )}
        </div>
        <div className="lg:sticky lg:top-24 lg:h-[calc(100vh-8rem)]">
          <NegotiationChat room={room} me={user} onAddonPay={payAddon} onAddonSkip={skipAddon} busyAddon={busy} />
        </div>
      </div>

      {/* Interactive Order Modification Studio */}
      <ModifyOrderModal
        order={order}
        isOpen={modifyOpen}
        onClose={() => setModifyOpen(false)}
        onUpdated={(updated) => {
          setOrder(updated);
          setNotice({ tone: 'ok', text: '✓ Order scope successfully updated.' });
        }}
      />
    </div>
  );
}

