import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, money, timeAgo } from '../../lib/api.js';
import { getSocket } from '../../lib/socket.js';
import { OrderRow, STAGES } from '../../components/Order.jsx';

export default function Orders() {
  const [orders, setOrders] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api('/api/client/orders').then((d) => setOrders(d.orders)).catch((e) => setError(e.message));
    const s = getSocket();
    const onUpdate = (o) =>
      setOrders((list) => {
        if (!list) return list;
        const rest = list.filter((x) => x.id !== o.id);
        return [o, ...rest];
      });
    s?.on('order:updated', onUpdate);
    return () => s?.off('order:updated', onUpdate);
  }, []);

  const active = orders?.filter((o) => o.status !== 'completed') || [];
  const past = orders?.filter((o) => o.status === 'completed') || [];

  return (
    <div className="mx-auto max-w-[1200px] px-6 pb-20 pt-12">
      <p className="eyebrow">Your table</p>
      <h1 className="display rise mt-3 text-[clamp(56px,6vw,96px)]">
        Orders<em className="italic text-brand-500">.</em>
      </h1>
      {error && <p className="mt-6 font-mono text-xs text-brand-600">{error}</p>}
      {orders && orders.length === 0 && (
        <div className="mt-14 border-t border-stone-300 pt-10">
          <p className="display text-4xl text-stone-500">Nothing on the table <em className="italic">yet.</em></p>
          <Link className="btn-primary mt-6" to="/client/new">Start a project →</Link>
        </div>
      )}
      {[['On the stove', active], ['Served', past]].map(([label, list]) =>
        list.length ? (
          <section key={label} className="mt-14">
            <div className="flex items-baseline justify-between border-b border-stone-300 pb-3">
              <h2 className="eyebrow">{label}</h2>
              <span className="font-mono text-[11px] text-stone-400">{String(list.length).padStart(2, '0')}</span>
            </div>
            {list.map((o) => (
              <OrderRow
                key={o.id}
                order={o}
                to={`/client/orders/${o.id}`}
                meta={`${o.type === 'menu' ? 'Fixed price' : 'With custom work'} · updated ${timeAgo(o.updatedAt)}${o.paid && o.stage >= 0 ? ` · ${STAGES[o.stage].label}` : ''}`}
              />
            ))}
          </section>
        ) : null,
      )}
    </div>
  );
}
