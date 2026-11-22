import { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { useAuth, homeFor } from '../context/AuthContext.jsx';
import { Logo } from '../components/Layout.jsx';

const TICKER = ['Proof-of-Delivery Escrow', 'AI Code Auditor', 'Evidence · file + line', 'Scope-Creep Shield', 'Proof Score reputation', 'Live GitHub Tracking', 'Refund what was never built'];

/** The signature visual: a kitchen ticket where every line item is paid out only when the code proves it. */
function Receipt() {
  const lines = [
    ['Landing page', '300', 'released', 'app/page.tsx:12'],
    ['Auth module', '250', 'released', 'lib/auth.ts:41'],
    ['AI FAQ chatbot', '1,200', 'proving', '2/3 criteria'],
    ['WhatsApp booking', '900', 'held', 'not found yet'],
  ];
  return (
    <div className="relative">
      <div className="absolute -inset-4 rounded-3xl bg-gradient-to-tr from-leaf/20 via-brand-500/10 to-transparent blur-2xl opacity-75" />
      <div className="print ticket relative w-[320px] rotate-[-2deg] px-6 pb-7 pt-8 font-mono text-[11.5px] text-white">
        <div className="flex items-baseline justify-between">
          <span className="font-display text-2xl italic tracking-tight text-white">Escrow Ticket</span>
          <span className="text-brand-400 font-semibold">№ CD-1042</span>
        </div>
        <p className="mt-1 text-[10px] uppercase tracking-[0.16em] text-stone-400">Dental clinic · paid on proof</p>
        <div className="rule-dashed my-4" />
        <ul className="space-y-3">
          {lines.map(([n, p, st, ev]) => (
            <li key={n}>
              <div className="flex items-baseline gap-2">
                <span className={st === 'released' ? 'text-leaf' : st === 'proving' ? 'text-amber-300' : 'text-stone-400'}>{st === 'released' ? '✓' : st === 'proving' ? '◐' : '⛨'}</span>
                <span className="text-stone-300">{n}</span>
                <span className="leader" />
                <span className="text-white font-medium">${p}</span>
              </div>
              <p className={`ml-5 text-[9.5px] uppercase tracking-[0.14em] ${st === 'released' ? 'text-leaf/80' : st === 'proving' ? 'text-amber-300/80' : 'text-stone-500'}`}>
                {st === 'released' ? `released · ${ev}` : st === 'proving' ? `auditing · ${ev}` : `held · ${ev}`}
              </p>
            </li>
          ))}
        </ul>
        <div className="rule-dashed my-4" />
        <div className="flex h-2 overflow-hidden rounded-full bg-white/10">
          <span className="h-full bg-leaf" style={{ width: '20%' }} />
          <span className="h-full bg-amber-400/50" style={{ width: '80%' }} />
        </div>
        <div className="mt-2 flex justify-between text-[10px] uppercase tracking-[0.14em]">
          <span className="text-leaf">$550 released</span>
          <span className="text-amber-300">$2,100 held</span>
        </div>
        <p className="mt-4 text-[10px] text-stone-400">🔎 audit of a41c9e2 · 38 files read</p>
        <p className="mt-5 text-center text-[10px] uppercase tracking-[0.3em] text-stone-500">no proof · no payout</p>
      </div>
    </div>
  );
}

function Frame({ children, title, subtitle }) {
  return (
    <div className="grid min-h-full lg:grid-cols-[1.25fr_1fr]">
      <section className="relative hidden flex-col overflow-hidden border-r border-white/10 px-12 pb-0 pt-10 lg:flex bg-[#08090d]">
        <div className="flex items-center justify-between">
          <Logo />
          <span className="pill-cyber text-leaf">Proof-of-Delivery Protocol</span>
        </div>
        <div className="mt-[6vh] flex min-h-0 flex-1 flex-col">
          <h1 className="display rise text-[clamp(54px,6.2vw,114px)] text-white">
            Pay for proof,
            <br />
            <em className="italic bg-gradient-to-r from-leaf to-cyan bg-clip-text text-transparent">not promises.</em>
          </h1>
          <div className="mt-6 grid flex-1 grid-cols-[minmax(0,1fr)_auto] items-start gap-10 pb-8">
            <div className="rise pt-4" style={{ animationDelay: '.15s' }}>
              <p className="max-w-sm text-[17px] leading-relaxed text-stone-400">
                The software marketplace where money moves only when code proves it. Order off a menu, lock the scope — then an AI auditor reads
                every commit and releases escrow item by item, citing the exact file and line.
              </p>
              <dl className="mt-10 grid max-w-sm grid-cols-3 gap-6 border-t border-white/10 pt-5">
                {[
                  ['01', 'Scope', 'AI-priced contract'],
                  ['02', 'Escrow', 'Held per item'],
                  ['03', 'Proof', 'Released by code'],
                ].map(([n, k, v]) => (
                  <div key={n}>
                    <dt className="font-mono text-[10px] text-leaf uppercase tracking-widest">{n}</dt>
                    <dd className="mt-1 font-display text-2xl leading-none text-white">{k}</dd>
                    <dd className="mt-1 text-xs text-stone-500">{v}</dd>
                  </div>
                ))}
              </dl>

              <div className="mt-8 flex items-center gap-3 font-mono text-[11px] text-stone-500">
                <span className="h-2 w-2 rounded-full bg-leaf animate-pulse" />
                <span>Others release money on a click. We release it on evidence.</span>
              </div>
            </div>
            <div className="pr-2 pt-2 xl:pr-8">
              <Receipt />
            </div>
          </div>
        </div>
        <div className="-mx-12 overflow-hidden border-t border-white/10 py-4 bg-black/40">
          <div className="marquee flex w-max gap-10 whitespace-nowrap font-mono text-[11px] uppercase tracking-[0.2em] text-stone-400">
            {[...TICKER, ...TICKER, ...TICKER, ...TICKER].map((t, i) => (
              <span key={i} className="flex items-center gap-10">
                {t} <span className="text-leaf">✺</span>
              </span>
            ))}
          </div>
        </div>
      </section>
      <section className="flex items-center justify-center px-6 py-12 bg-[#0c0e14]">
        <div className="w-full max-w-[400px]">
          <div className="mb-12 lg:hidden"><Logo /></div>
          <p className="eyebrow text-brand-400">{subtitle}</p>
          <h2 className="display mt-2 text-6xl text-white">{title}</h2>
          <div className="mt-8">{children}</div>
        </div>
      </section>
    </div>
  );
}

function Field({ label, ...props }) {
  return (
    <label className="block">
      <span className="label text-stone-400">{label}</span>
      <input
        {...props}
        className="w-full rounded-xl border border-white/10 bg-white/[0.03] px-4 py-3 text-base text-white outline-none transition placeholder:text-stone-600 focus:border-brand-500 focus:bg-white/[0.06] focus:ring-1 focus:ring-brand-500"
      />
    </label>
  );
}

export function Login() {
  const { user, login } = useAuth();
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  if (user) return <Navigate to={homeFor(user)} replace />;

  const submit = async (e, creds) => {
    e?.preventDefault();
    setBusy(true);
    setError('');
    try {
      const u = await login(creds?.email ?? email, creds?.password ?? password);
      nav(homeFor(u));
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Frame title={<>Welcome <em className="italic text-brand-400">back</em></>} subtitle="Portal Access">
      <form onSubmit={submit} className="space-y-5">
        <Field label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoComplete="email" />
        <Field label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required autoComplete="current-password" />
        {error && <p className="font-mono text-xs text-brand-400 bg-brand-500/10 p-2.5 rounded-lg border border-brand-500/20">{error}</p>}
        <button className="btn-primary w-full py-3.5 text-base font-semibold" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign in to ScopeGuard'} <span aria-hidden>→</span>
        </button>
      </form>
      <div className="mt-8">
        <p className="eyebrow mb-3 flex items-center gap-3 text-stone-400">
          <span className="h-px flex-1 bg-white/10" /> 1-Click Demo Seats <span className="h-px flex-1 bg-white/10" />
        </p>
        <div className="grid grid-cols-2 gap-3">
          {[
            ['client@demo.dev', 'Client', 'Buyer seat', 'Order · escrow · verify'],
            ['dev@demo.dev', 'Developer', 'Builder seat', 'Ship · prove · get paid'],
          ].map(([em, role, where, desc]) => (
            <button
              key={em}
              disabled={busy}
              onClick={() => submit(null, { email: em, password: 'demo1234' })}
              className="group relative overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03] p-4 text-left transition-all duration-300 hover:border-brand-500/50 hover:bg-white/[0.06] hover:shadow-lg hover:shadow-brand-500/10"
            >
              <div className="flex items-center justify-between">
                <span className="font-display text-2xl text-white group-hover:text-brand-300">{role}</span>
                <span className="text-stone-500 transition group-hover:translate-x-1 group-hover:text-brand-400">→</span>
              </div>
              <span className="mt-1 block font-mono text-[10px] uppercase tracking-[0.14em] text-brand-400">
                {where}
              </span>
              <span className="mt-1 block text-xs text-stone-400">{desc}</span>
            </button>
          ))}
        </div>
      </div>
      <p className="mt-8 text-sm text-stone-400 text-center">
        New here?{' '}
        <Link className="text-white underline decoration-stone-500 underline-offset-4 hover:decoration-brand-400" to="/register">
          Create an account
        </Link>
      </p>
    </Frame>
  );
}


export function Register() {
  const { user, register } = useAuth();
  const nav = useNavigate();
  const [form, setForm] = useState({ name: '', email: '', password: '', role: 'client' });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  if (user) return <Navigate to={homeFor(user)} replace />;
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      const u = await register(form);
      nav(homeFor(u));
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Frame title={<>Pull up a <em className="italic">chair</em></>} subtitle="Create account">
      <form onSubmit={submit} className="space-y-7">
        <div>
          <span className="label">I’m here to</span>
          <div className="grid grid-cols-2 gap-3">
            {[
              ['client', 'Order', 'I need software built'],
              ['dev', 'Cook', 'I build software'],
            ].map(([role, label, hint]) => (
              <button
                type="button"
                key={role}
                onClick={() => setForm({ ...form, role })}
                className={`rounded-xl border p-4 text-left transition duration-300 ${
                  form.role === role ? 'border-ink bg-ink text-paper' : 'border-stone-300 hover:border-ink'
                }`}
              >
                <span className="font-display text-2xl leading-none">{label}</span>
                <span className={`mt-1 block text-xs ${form.role === role ? 'text-stone-400' : 'text-stone-500'}`}>{hint}</span>
              </button>
            ))}
          </div>
        </div>
        <Field label="Name" value={form.name} onChange={set('name')} required autoComplete="name" />
        <Field label="Email" type="email" value={form.email} onChange={set('email')} required autoComplete="email" />
        <Field label="Password" type="password" minLength={6} value={form.password} onChange={set('password')} required autoComplete="new-password" />
        {error && <p className="font-mono text-xs text-brand-600">{error}</p>}
        <button className="btn-primary w-full py-3.5 text-base" disabled={busy}>
          {busy ? 'Creating…' : 'Create account'} <span aria-hidden>→</span>
        </button>
      </form>
      <p className="mt-10 text-sm text-stone-500">
        Have an account?{' '}
        <Link className="text-ink underline decoration-stone-300 underline-offset-4 hover:decoration-ink" to="/login">
          Sign in
        </Link>
      </p>
    </Frame>
  );
}
