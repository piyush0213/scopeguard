import { NavLink, Outlet, Navigate, useNavigate, Link } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { useAuth, homeFor } from '../context/AuthContext.jsx';
import { getSocket } from '../lib/socket.js';
import { money } from '../lib/api.js';

export function Logo({ dark = false, size = 'text-[26px]' }) {
  return (
    <span className={`inline-flex items-baseline gap-1 font-display ${size} leading-none tracking-[-0.03em] ${dark ? 'text-paper' : 'text-ink'}`}>
      Scope<em className="italic">guard</em>
      <span className="ml-0.5 inline-block h-1.5 w-1.5 translate-y-[-0.15em] rounded-full bg-brand-500" />
    </span>
  );
}

export function Protected({ role }) {
  const { user, loading } = useAuth();
  if (loading) return <FullSpinner />;
  if (!user) return <Navigate to="/login" replace />;
  if (role && user.role !== role) return <Navigate to={homeFor(user)} replace />;
  return <Shell />;
}

export function FullSpinner() {
  return (
    <div className="grid h-full place-items-center">
      <div className="flex items-center gap-3 font-mono text-xs uppercase tracking-[0.2em] text-stone-500">
        <span className="h-2 w-2 animate-pulse rounded-full bg-brand-500" /> Loading
      </div>
    </div>
  );
}

const NAV = {
  client: [
    ['/client/new', 'New project'],
    ['/client/orders', 'My orders'],
  ],
  dev: [['/dev/dashboard', 'Order queue']],
};

function Shell() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const [toasts, setToasts] = useState([]);
  const [online, setOnline] = useState(false);

  useEffect(() => {
    const s = getSocket();
    if (!s) return;
    const push = (t) => {
      const id = Math.random().toString(36).slice(2);
      setToasts((x) => [...x, { id, ...t }]);
      setTimeout(() => setToasts((x) => x.filter((y) => y.id !== id)), 6500);
    };
    const on = () => setOnline(true);
    const off = () => setOnline(false);
    const handlers =
      user.role === 'dev'
        ? {
            'quote:new': (o) => push({ tag: 'New quote', title: o.id, body: o.title, to: `/dev/orders/${o.id}` }),
            'order:paid': (o) => push({ tag: 'Paid', title: o.id, body: `${money(o.totalCents)} — ready to accept`, to: `/dev/orders/${o.id}` }),
            'scope:alert': (a) => push({ tag: 'Scope change', title: a.orderId, body: a.reason, to: `/dev/orders/${a.orderId}`, hot: true }),
          }
        : {};
    if (s.connected) on();
    s.on('connect', on);
    s.on('disconnect', off);
    for (const [ev, fn] of Object.entries(handlers)) s.on(ev, fn);
    return () => {
      s.off('connect', on);
      s.off('disconnect', off);
      for (const [ev, fn] of Object.entries(handlers)) s.off(ev, fn);
    };
  }, [user.role]);

  const isDev = user.role === 'dev';
  return (
    <div className="flex h-full flex-col">
      <header className="sticky top-0 z-30 border-b border-white/10 bg-[#08090d]/85 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-[1400px] items-center gap-8 px-6">
          <Link to={homeFor(user)} className="flex items-center gap-3">
            <Logo />
            <span className="pill-cyber hidden sm:inline text-brand-400">
              {isDev ? 'Kitchen Command' : 'Dining Counter'}
            </span>
          </Link>
          <nav className="flex gap-6">
            {NAV[user.role].map(([to, label]) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  `relative py-1 text-sm font-medium transition-colors after:absolute after:inset-x-0 after:-bottom-0.5 after:h-[2px] after:origin-left after:bg-brand-500 after:transition-transform after:duration-300 ${
                    isActive ? 'text-white after:scale-x-100' : 'text-stone-400 after:scale-x-0 hover:text-white hover:after:scale-x-100'
                  }`
                }
              >
                {label}
              </NavLink>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-5 text-sm">
            <span className="hidden items-center gap-2 font-mono text-[11px] uppercase tracking-[0.16em] text-stone-400 md:flex">
              <span className={`h-2 w-2 rounded-full ${online ? 'bg-emerald-400 shadow-sm shadow-emerald-400 animate-pulse' : 'bg-stone-500'}`} />
              {online ? 'Live Telemetry' : 'Connecting…'}
            </span>
            <span className="hidden font-medium text-stone-300 sm:inline">{user.name}</span>
            <button
              className="rounded-full border border-white/15 bg-white/5 px-4 py-1.5 text-xs font-mono uppercase tracking-wider text-stone-300 transition hover:border-brand-500/50 hover:bg-white/10 hover:text-white"
              onClick={() => {
                logout();
                nav('/login');
              }}
            >
              Log out
            </button>
          </div>
        </div>
      </header>
      <main className="min-h-0 flex-1 overflow-auto">
        <Outlet />
      </main>
      <div className="pointer-events-none fixed bottom-6 right-6 z-50 flex w-84 flex-col gap-2.5">
        {toasts.map((t) => (
          <button
            key={t.id}
            onClick={() => t.to && nav(t.to)}
            className={`pointer-events-auto slide-in rounded-2xl border p-4 text-left shadow-2xl backdrop-blur-xl transition hover:scale-[1.02] ${
              t.hot
                ? 'border-brand-500/50 bg-[#1f100c]/90 text-white shadow-brand-500/20'
                : 'border-white/10 bg-[#12141f]/90 text-white shadow-black/80'
            }`}
          >
            <div className="flex items-center justify-between font-mono text-[10px] uppercase tracking-[0.16em] text-brand-400">
              <span>{t.tag}</span>
              <span className="text-stone-400">{t.title}</span>
            </div>
            <p className="mt-1 text-sm font-medium leading-snug">{t.body}</p>
          </button>
        ))}
      </div>
    </div>
  );
}
