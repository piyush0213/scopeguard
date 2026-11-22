import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { api, money, totalOf } from '../../lib/api.js';
import { useOrderRoom } from '../../lib/useOrderRoom.js';
import { useAuth } from '../../context/AuthContext.jsx';
import { FullSpinner } from '../../components/Layout.jsx';
import { Brief, LiveTracker, NegotiationChat, STAGES, WorkspaceHeader, NextStep } from '../../components/Order.jsx';
import { ScopeGuardHud } from '../../components/ScopeGuardHud.jsx';
import { ProofVault } from '../../components/ProofVault.jsx';

export default function DevWorkspace() {
  const { id } = useParams();
  const { user } = useAuth();
  const room = useOrderRoom(id);
  const { order, setOrder, error, git } = room;
  const [addonPrefill, setAddonPrefill] = useState(null);
  const [replayOpen, setReplayOpen] = useState(false);

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setReplayOpen((v) => !v);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  if (error) return <p className="p-6 text-red-600">{error}</p>;
  if (!order) return <FullSpinner />;

  return (
    <div className="mx-auto max-w-[1400px] px-6 pb-16 pt-8">
      <WorkspaceHeader
        back={['/dev/dashboard', 'Queue']}
        order={order}
        amount={money(order.paid ? order.totalCents : totalOf(order.quote?.modules))}
        extra={`for ${order.clientName}`}
      />
      <div className="mb-6">
        <ScopeGuardHud order={order} />
      </div>
      <NextStep order={order} role="dev" />

      <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_430px]">
        <div className="space-y-8">
          {order.quote && !order.paid && <ModuleEditor order={order} onSaved={setOrder} />}
          {order.paid && (
            <>
              <BuildControls order={order} git={git} onChange={setOrder} onReplay={() => setReplayOpen(true)} onReload={room.reload} />
              <ProofVault order={order} role="dev" />
              <AddonCreator order={order} prefill={addonPrefill} onDone={() => setAddonPrefill(null)} />
              <LiveTracker order={order} />
            </>
          )}
          <Brief brief={order.quote?.brief} />
          {order.scoping?.idea && (
            <div className="card p-6">
              <p className="eyebrow">From the client</p>
              <p className="mt-3 font-display text-2xl leading-snug">“{order.scoping.idea}”</p>
              {order.scoping.custom && (
                <p className="mt-4 text-sm">
                  <span className="font-mono text-[10px] uppercase tracking-[0.14em] text-brand-600">Chef’s special · </span>
                  {order.scoping.custom}
                </p>
              )}
              {order.scoping.qa && (
                <dl className="mt-5 divide-y divide-stone-200 border-t border-stone-200">
                  {order.scoping.qa.map((x, i) => (
                    <div key={i} className="grid gap-1 py-3 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] md:gap-6">
                      <dt className="text-sm text-stone-500">{x.question}</dt>
                      <dd className="text-sm">{x.answer}</dd>
                    </div>
                  ))}
                </dl>
              )}
            </div>
          )}
        </div>
        <div className="lg:sticky lg:top-24 lg:h-[calc(100vh-8rem)]">
          <NegotiationChat room={room} me={user} onCreateAddon={(s, messageId) => setAddonPrefill({ ...s, sourceMessageId: messageId, key: Date.now() })} />
        </div>
      </div>
      {replayOpen && <ReplayDrawer order={order} onClose={() => setReplayOpen(false)} onResult={setOrder} />}
    </div>
  );
}

/* --------------------------------------------------------------------- Quote editor (pre-pay) */
function ModuleEditor({ order, onSaved }) {
  const q = order.quote;
  const [mods, setMods] = useState(q.modules);
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [dirty, setDirty] = useState(false);

  // Pull in client toggles / server changes when we have no unsaved edits.
  useEffect(() => {
    if (!dirty) setMods(q.modules);
  }, [q.modules, q.version, dirty]);

  const update = (i, patch) => {
    setDirty(true);
    setMods((m) => m.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  };
  const add = () => {
    setDirty(true);
    setMods((m) => [...m, { id: `m${Date.now().toString(36)}`, name: 'New module', description: '', price_cents: 20000, optional: true, included: true }]);
  };
  const remove = (i) => {
    setDirty(true);
    setMods((m) => m.filter((_, j) => j !== i));
  };

  const submit = async () => {
    setBusy(true);
    setErr('');
    try {
      const path = q.status === 'ai_draft' ? `/api/quotes/${q.id}/approve` : `/api/quotes/${q.id}/revise`;
      const d = await api(path, { method: 'PATCH', body: { modules: mods, note } });
      setDirty(false);
      setNote('');
      onSaved(d.order);
    } catch (e) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  };

  const isDraft = q.status === 'ai_draft';
  return (
    <div className="card overflow-hidden">
      <div className="flex items-center justify-between border-b border-stone-100 p-5">
        <div>
          <p className="eyebrow">{isDraft ? 'AI draft · review' : `Live quote · v${q.version}`}</p>
          <h3 className="display mt-2 text-4xl">{isDraft ? <>Season the <em className="italic">quote</em></> : <>Haggle, <em className="italic">live</em></>}</h3>
          <p className="text-xs text-stone-500">
            {isDraft ? 'Adjust prices or modules, then send it to the client.' : 'Edit and push a revision — the client’s quote updates instantly.'}
          </p>
        </div>
        {!isDraft && (
          <span className="rounded-full bg-sky-100 px-2 py-0.5 text-xs font-semibold text-sky-700">
            Client sees {money(totalOf(q.modules))}
          </span>
        )}
      </div>
      <div className="divide-y divide-stone-100">
        {mods.map((m, i) => (
          <div key={m.id} className={`grid grid-cols-[1fr_120px_auto] gap-3 p-4 ${m.optional && !m.included ? 'bg-stone-50' : ''}`}>
            <div className="space-y-1.5">
              <input className="input font-semibold" value={m.name} onChange={(e) => update(i, { name: e.target.value })} />
              <input className="input text-xs" value={m.description} placeholder="Description" onChange={(e) => update(i, { description: e.target.value })} />
              <label className="flex items-center gap-2 text-xs text-stone-500">
                <input type="checkbox" checked={m.optional} onChange={(e) => update(i, { optional: e.target.checked })} />
                Optional (client can toggle)
                {m.optional && !m.included && <span className="font-semibold text-amber-600">· client toggled off</span>}
                {m.menu && <span className="rounded bg-brand-50 px-1.5 font-bold text-brand-600">MENU ITEM</span>}
              </label>
            </div>
            <div>
              <div className="relative">
                <span className="absolute left-3 top-2 text-sm text-stone-400">$</span>
                <input
                  className="input pl-6 text-right font-mono"
                  type="number"
                  min="0"
                  value={m.price_cents / 100}
                  onChange={(e) => update(i, { price_cents: Math.round(Number(e.target.value) * 100) })}
                />
              </div>
            </div>
            <button className="self-start rounded-lg p-2 text-stone-400 hover:bg-red-50 hover:text-red-600" onClick={() => remove(i)} title="Remove">✕</button>
          </div>
        ))}
      </div>
      <div className="space-y-3 bg-stone-50 p-5">
        <button className="btn-ghost text-xs" onClick={add}>+ Add module</button>
        <input className="input" placeholder={isDraft ? 'Optional note to the client' : 'Revision note, e.g. “Swapped FAQ training for $250 CSV upload”'} value={note} onChange={(e) => setNote(e.target.value)} />
        {err && <p className="text-sm text-red-600">{err}</p>}
        <div className="flex items-center justify-between">
          <span className="text-sm text-stone-500">
            <span className="font-mono text-[11px] uppercase tracking-[0.14em]">New total</span> <b className="ml-2 font-display text-4xl font-normal text-ink">{money(totalOf(mods))}</b>
          </span>
          <div className="flex gap-2">
            {dirty && <button className="btn-ghost" onClick={() => { setMods(q.modules); setDirty(false); }}>Reset</button>}
            <button className="btn-primary" disabled={busy || (!isDraft && !dirty)} onClick={submit}>
              {busy ? 'Sending…' : isDraft ? 'Approve & Send to Client' : 'Push Revision'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------- Build controls (post-pay) */
/* ------------------------------------------------------------------ GitHub repo connector */
const LAST_REPO_KEY = 'sg_last_repo';

function RepoConnector({ order, onChange, onReload }) {
  const [url, setUrl] = useState(() => localStorage.getItem(LAST_REPO_KEY) || '');
  const [editing, setEditing] = useState(!order.repoFullName);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const sync = order.repoSync || {};

  const connect = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErr('');
    try {
      const d = await api(`/api/orders/${order.id}/repo`, { method: 'POST', body: { url } });
      localStorage.setItem(LAST_REPO_KEY, url);
      onChange(d.order);
      setEditing(false);
      onReload();
    } catch (e2) {
      setErr(e2.message);
    } finally {
      setBusy(false);
    }
  };
  const disconnect = async () => {
    setBusy(true);
    setErr('');
    try {
      const d = await api(`/api/orders/${order.id}/repo`, { method: 'DELETE' });
      onChange(d.order);
      setEditing(true);
      onReload();
    } catch (e2) {
      setErr(e2.message);
    } finally {
      setBusy(false);
    }
  };

  if (order.repoFullName && !editing) {
    return (
      <div className="mt-4 rounded-xl border border-stone-300 bg-paper p-3">
        <div className="flex flex-wrap items-center gap-2">
          <span className="font-mono text-xs text-stone-400">repo</span>
          <a className="font-mono text-sm font-semibold text-ink underline-offset-2 hover:underline" href={`https://github.com/${order.repoFullName}`} target="_blank" rel="noreferrer">
            {order.repoFullName}
          </a>
          <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold ${sync.error ? 'bg-brand-100 text-brand-600' : 'bg-leaf/15 text-leaf'}`}>
            {sync.error ? '● Sync error' : sync.mode === 'webhook' ? '● Live webhook + auto-sync' : '● Auto-sync on'}
          </span>
          <span className="font-mono text-xs text-stone-400">branch {order.branchName}</span>
          <span className="ml-auto flex gap-1">
            <button className="rounded-lg px-2.5 py-1 text-xs text-stone-600 hover:bg-stone-200 hover:text-ink" onClick={() => setEditing(true)} disabled={busy}>Change</button>
            <button className="rounded-lg px-2 py-1 text-xs text-stone-400 hover:bg-stone-200 hover:text-brand-600" onClick={disconnect} disabled={busy}>Disconnect</button>
          </span>
        </div>
        {sync.error && <p className="mt-1 text-xs text-brand-600">{sync.error}</p>}
        {!sync.error && sync.note && <p className="mt-1 text-xs text-stone-400">{sync.note}</p>}
        {order.stage === 0 && <p className="mt-1 text-xs text-amber-400">Accept the order to start tracking.</p>}
        {err && <p className="mt-1 text-xs text-brand-600">{err}</p>}
      </div>
    );
  }

  return (
    <form onSubmit={connect} className="mt-4 rounded-xl border border-dashed border-stone-300 p-3">
      <p className="mb-2 text-xs text-stone-400">
        <b className="text-ink">Connect a GitHub repo</b> — branch creation, CI results, PRs, preview deploys and merges on{' '}
        <code className="text-ink">{order.branchName}</code> will move the client’s tracker automatically.
      </p>
      <div className="flex gap-2">
        <input
          className="input border-stone-300 bg-paper font-mono text-ink"
          placeholder="https://github.com/you/your-repo"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
        />
        <button className="btn-accent" disabled={busy || !url.trim()}>{busy ? 'Connecting…' : 'Connect'}</button>
        {order.repoFullName && (
          <button type="button" className="btn-ghost" onClick={() => setEditing(false)}>Cancel</button>
        )}
      </div>
      {err && <p className="mt-2 text-xs text-brand-600">{err}</p>}
    </form>
  );
}

function BuildControls({ order, git, onChange, onReplay, onReload }) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [cmds, setCmds] = useState(git);
  const [preview, setPreview] = useState(order.previewUrl || '');
  useEffect(() => setCmds(git), [git]);

  const run = async (fn) => {
    setBusy(true);
    setErr('');
    try {
      await fn();
    } catch (e) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="card p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="font-mono text-[10px] uppercase tracking-[0.18em] text-stone-400">Build controls</p>
          <p className="display mt-2 text-4xl">
            <span className="mr-2 font-mono text-sm text-brand-400">{STAGES[order.stage].icon}</span><em className="italic">{STAGES[order.stage].label}</em>
            {order.ciFailed && <span className="ml-2 text-sm text-brand-600">· CI failing</span>}
          </p>
        </div>
        <div className="flex gap-2">
          <button className="btn-ghost" onClick={onReplay} title="Ctrl/Cmd + K">
            Replay <kbd className="rounded bg-stone-700 px-1 text-[10px]">Ctrl K</kbd>
          </button>
          {order.stage === 0 && (
            <button
              className="btn-accent"
              disabled={busy}
              onClick={() => run(async () => {
                const d = await api(`/api/orders/${order.id}/accept`, { method: 'POST' });
                onChange(d.order);
                setCmds(d.git);
              })}
            >
              Accept Order
            </button>
          )}
        </div>
      </div>
      {order.stage <= 6 && <RepoConnector order={order} onChange={onChange} onReload={onReload} />}
      {order.stage >= 1 && cmds && (
        <div className="mt-4">
          <p className="mb-1 text-xs text-stone-400">
            {order.repoFullName
              ? `Work on this branch in ${order.repoFullName} — every push, CI run, PR and merge updates the client automatically:`
              : 'Connect a repo above, then work on this branch:'}
          </p>
          <pre className="whitespace-pre-wrap break-all rounded-xl bg-paper border border-stone-200 p-4 font-mono text-[12px] leading-relaxed text-ink">
            {cmds.map((c) => `$ ${c}`).join('\n')}
          </pre>
        </div>
      )}
      {order.stage >= 1 && order.stage < 6 && (
        <form
          className="mt-4 flex gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            run(async () => {
              const d = await api(`/api/orders/${order.id}/preview`, { method: 'POST', body: { url: preview } });
              onChange(d.order);
            });
          }}
        >
          <input className="input border-stone-300 bg-paper text-ink" placeholder="Preview URL (Vercel/Netlify) → Taste Test" value={preview} onChange={(e) => setPreview(e.target.value)} />
          <button className="btn-accent" disabled={busy || !preview}>Attach</button>
        </form>
      )}
      {err && <p className="mt-2 text-sm text-brand-600">{err}</p>}
    </div>
  );
}

/* ------------------------------------------------------------------- ScopeGuard add-on creator */
function AddonCreator({ order, prefill, onDone }) {
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [price, setPrice] = useState('');
  const [source, setSource] = useState(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  useEffect(() => {
    if (!prefill) return;
    setTitle(prefill.title);
    setDesc(prefill.description || '');
    setPrice(String((prefill.priceCents || 0) / 100));
    setSource(prefill.sourceMessageId);
  }, [prefill]);

  if (order.stage > 5) return null;
  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setErr('');
    try {
      await api(`/api/orders/${order.id}/addons`, {
        method: 'POST',
        body: { title, description: desc, priceCents: Math.round(Number(price) * 100), sourceMessageId: source },
      });
      setTitle('');
      setDesc('');
      setPrice('');
      setSource(null);
      onDone();
    } catch (e2) {
      setErr(e2.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <form onSubmit={submit} className={`card p-5 ${prefill ? 'border-red-300 ring-2 ring-red-100' : ''}`}>
      <div className="mb-3 flex items-center justify-between">
        <div>
          <p className="eyebrow">ScopeGuard</p>
          <h3 className="display mt-2 text-3xl">Add to <em className="italic">order</em></h3>
          <p className="text-xs text-stone-500">Send a priced “Add to Order” card. The client can pay in one go or skip.</p>
        </div>
      </div>
      <div className="grid gap-2 sm:grid-cols-[1fr_120px]">
        <input className="input" placeholder="Add-on title, e.g. Google Calendar booking" value={title} onChange={(e) => setTitle(e.target.value)} />
        <div className="relative">
          <span className="absolute left-3 top-2 text-sm text-stone-400">$</span>
          <input className="input pl-6 text-right font-mono" type="number" min="1" placeholder="350" value={price} onChange={(e) => setPrice(e.target.value)} />
        </div>
      </div>
      <input className="input mt-2" placeholder="Short description (optional)" value={desc} onChange={(e) => setDesc(e.target.value)} />
      {err && <p className="mt-2 text-sm text-red-600">{err}</p>}
      <button className="btn-dark mt-3 w-full" disabled={busy || !title || !price}>{busy ? 'Sending…' : 'Send “Add to Order” card'}</button>
    </form>
  );
}

/* ------------------------------------------------------------------ Demo replay drawer (Ctrl+K) */
function ReplayDrawer({ order, onClose, onResult }) {
  const [info, setInfo] = useState(null);
  const [busy, setBusy] = useState('');
  const [log, setLog] = useState([]);

  useEffect(() => {
    api(`/demo/replay/${order.id}`).then(setInfo).catch((e) => setLog((l) => [`✖ ${e.message}`, ...l]));
  }, [order.id]);

  const fire = async (stage, label) => {
    setBusy(stage);
    try {
      const d = await api(`/demo/replay/${order.id}/${stage}`, { method: 'POST' });
      onResult(d.order);
      setLog((l) => [`${d.applied ? '✓' : '·'} ${label} (${d.source} payload) → ${d.detail}`, ...l]);
    } catch (e) {
      setLog((l) => [`✖ ${label}: ${e.message}`, ...l]);
    } finally {
      setBusy('');
    }
  };

  const STEPS = [
    ['2', 'Branch created', 'create'],
    ['ci_fail', 'CI failed', 'workflow_run · failure'],
    ['3', 'CI passed', 'workflow_run · success'],
    ['4', 'PR opened', 'pull_request · opened'],
    ['5', 'Preview deployed', 'deployment_status · success'],
    ['6', 'PR merged', 'pull_request · closed+merged'],
  ];

  return (
    <div className="fixed inset-0 z-40 flex justify-end bg-black/60 backdrop-blur-sm" onClick={onClose}>
      <div className="slide-in h-full w-full max-w-md overflow-y-auto border-l border-stone-200 bg-surface p-6 text-ink" onClick={(e) => e.stopPropagation()}>
        <div className="mb-1 flex items-center justify-between">
          <h3 className="display text-4xl">Demo <em className="italic">replay</em></h3>
          <button onClick={onClose} className="text-stone-500 hover:text-ink" aria-label="Close">✕</button>
        </div>
        <p className="mb-5 text-sm text-stone-500">
          Wi-Fi failsafe. Re-fires the latest <b>recorded</b> GitHub webhook payloads (falls back to bundled samples) at{' '}
          <code className="text-ink">{order.branchName}</code> through the same state machine.
        </p>
        <div className="space-y-2">
          {STEPS.map(([stage, label, ev]) => (
            <button
              key={stage}
              disabled={!!busy}
              onClick={() => fire(stage, label)}
              className="flex w-full items-center justify-between rounded-xl border border-stone-300 px-4 py-3 text-left hover:border-brand-500 hover:bg-paper disabled:opacity-50"
            >
              <span>
                <span className="block font-semibold">{label}</span>
                <span className="font-mono text-xs text-stone-400">{ev}</span>
              </span>
              <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${info?.sources?.[stage] === 'recorded' ? 'bg-leaf/15 text-leaf' : 'bg-stone-200 text-stone-500'}`}>
                {busy === stage ? '…' : info?.sources?.[stage] || '—'}
              </span>
            </button>
          ))}
        </div>
        {log.length > 0 && (
          <pre className="mt-5 whitespace-pre-wrap rounded-xl bg-paper p-3 font-mono text-xs text-stone-600">{log.join('\n')}</pre>
        )}
        {info?.recent?.length > 0 && (
          <div className="mt-5">
            <p className="mb-1 text-xs font-semibold uppercase text-stone-400">Recent events for this order</p>
            <ul className="space-y-1 font-mono text-[11px] text-stone-400">
              {info.recent.map((e) => (
                <li key={e.delivery_id}>
                  {e.event_type}{e.action ? `.${e.action}` : ''} · {e.delivery_id.slice(0, 18)}
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
