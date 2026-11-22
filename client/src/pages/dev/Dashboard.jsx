import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, money, timeAgo } from '../../lib/api.js';
import { getSocket } from '../../lib/socket.js';
import { OrderRow, STAGES } from '../../components/Order.jsx';
import { ProofScore } from '../../components/ProofVault.jsx';
import { useAuth } from '../../context/AuthContext.jsx';

const TABS = [
  ['pending', 'New quotes', (o) => o.status === 'ai_draft'],
  ['negotiating', 'Negotiating', (o) => !o.paid && ['negotiating', 'awaiting_payment'].includes(o.status)],
  ['active', 'Cooking', (o) => o.paid && o.stage < 7],
  ['done', 'Served', (o) => o.stage === 7],
];

export default function DevDashboard() {
  const [orders, setOrders] = useState(null);
  const [tab, setTab] = useState('pending');
  const [fresh, setFresh] = useState({});
  const [status, setStatus] = useState(null);
  const { user } = useAuth();

  useEffect(() => {
    api('/api/dev/orders').then((d) => {
      setOrders(d.orders);
      const firstBusy = TABS.find(([, , f]) => d.orders.some(f));
      if (firstBusy) setTab(firstBusy[0]);
    });
    api('/api/system/status').then(setStatus).catch(() => {});
    const s = getSocket();
    const onUpdate = (o) => {
      if (o.status === 'scoping') return;
      setOrders((list) => (list ? [o, ...list.filter((x) => x.id !== o.id)] : list));
      setFresh((f) => ({ ...f, [o.id]: Date.now() }));
    };
    s?.on('order:updated', onUpdate);
    return () => s?.off('order:updated', onUpdate);
  }, []);

  const filter = TABS.find((t) => t[0] === tab)[2];
  const list = orders?.filter(filter) || [];

  return (
    <div className="mx-auto max-w-[1200px] px-6 pb-20 pt-12">
      <div className="flex flex-wrap items-end justify-between gap-6">
        <div>
          <p className="eyebrow">The kitchen</p>
          <h1 className="display rise mt-3 text-[clamp(56px,6vw,96px)]">
            Order <em className="italic text-brand-500">queue</em>
          </h1>
        </div>
        {status && (
          <ul className="flex flex-wrap gap-x-5 gap-y-1 pb-3 font-mono text-[10px] uppercase tracking-[0.14em] text-stone-500">
            {[
              [status.ai ? 'AI' : 'AI', status.ai],
              ['Stripe', status.stripe],
              ['GitHub', status.githubWebhook],
              ['Stripe webhook', status.stripeWebhook],
            ].map(([k, v]) => (
              <li key={k} className="flex items-center gap-1.5" title={typeof v === 'string' ? v : ''}>
                <span className={`h-1.5 w-1.5 rounded-full ${v ? 'bg-leaf' : 'bg-stone-300'}`} />
                {k}
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="mt-10">
        <ProofScore devId={user?.id} />
      </div>

      <div className="mt-12 flex gap-8 overflow-x-auto border-b border-stone-300 [scrollbar-width:none]">
        {TABS.map(([key, label, f]) => {
          const n = orders?.filter(f).length || 0;
          const on = tab === key;
          return (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`relative flex shrink-0 items-baseline gap-2 pb-3 text-[15px] transition ${on ? 'text-ink' : 'text-stone-500 hover:text-ink'}`}
            >
              {label}
              <sup className={`font-mono text-[10px] ${n && !on ? 'text-brand-500' : 'text-stone-400'}`}>{String(n).padStart(2, '0')}</sup>
              <span className={`absolute inset-x-0 -bottom-px h-px bg-ink transition-transform duration-500 ${on ? 'scale-x-100' : 'scale-x-0'}`} />
            </button>
          );
        })}
      </div>
      {!orders && <p className="py-16 text-center font-mono text-xs uppercase tracking-[0.2em] text-stone-400">Loading…</p>}
      {orders && list.length === 0 && <p className="py-20 text-center font-display text-3xl italic text-stone-400">Nothing on this rail.</p>}
      {list.map((o) => (
        <OrderRow
          key={`${o.id}-${fresh[o.id] || 0}`}
          order={o}
          to={`/dev/orders/${o.id}`}
          flash={!!fresh[o.id]}
          meta={`${o.clientName} · ${o.type === 'menu' ? 'Fixed price' : 'Custom'} · ${timeAgo(o.updatedAt)}${o.paid ? ` · ${STAGES[o.stage].label}` : ''}${o.repoFullName ? ` · ${o.repoFullName}` : ''}`}
        />
      ))}
    </div>
  );
}
