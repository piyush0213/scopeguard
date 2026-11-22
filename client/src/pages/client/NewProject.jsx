import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api, money, totalOf } from '../../lib/api.js';

const BRIEF_EXAMPLES = [
  ['Dental clinic', 'I run a dental clinic with 3 dentists. I want patients to find answers and book appointments online.'],
  ['Hair salon', 'I own a hair salon and want a simple website where clients can see services and prices.'],
  ['Café chain', 'We are a 3-café chain and need to track stock and daily sales in one place.'],
];
const CUSTOM_EXAMPLES = ['AI chatbot that answers patient FAQs', 'WhatsApp appointment reminders', 'Inventory dashboard with low-stock alerts'];
const MIN_BRIEF = 15;

function Bot({ children }) {
  return (
    <div className="slide-in flex gap-4">
      <span className="mt-1 grid h-7 w-7 shrink-0 place-items-center rounded-full bg-ink font-display text-sm italic text-paper">S</span>
      <div className="min-w-0 max-w-[85%] text-[15px] leading-relaxed text-ink">{children}</div>
    </div>
  );
}
function Me({ children }) {
  return (
    <div className="slide-in flex justify-end">
      <div className="max-w-[80%] rounded-2xl rounded-tr-md bg-ink px-4 py-3 text-[15px] leading-relaxed text-paper">{children}</div>
    </div>
  );
}

const QUESTION_STEPS = [
  [0, 'Reading your project brief'],
  [4, 'Spotting what changes scope and price'],
  [9, 'Writing clarifying questions'],
];
const QUOTE_STEPS = [
  [0, 'Analyzing your answers'],
  [6, 'Writing the project brief'],
  [14, 'Defining what’s in and out of scope'],
  [22, 'Splitting custom work into modules'],
  [30, 'Pricing each module'],
];

/** Staged progress while the LLM works, so a 10–35s generation never looks frozen. */
function AiProgress({ steps }) {
  const [elapsed, setElapsed] = useState(0);
  useEffect(() => {
    const start = Date.now();
    const t = setInterval(() => setElapsed(Math.floor((Date.now() - start) / 1000)), 500);
    return () => clearInterval(t);
  }, []);
  const current = steps.filter(([at]) => elapsed >= at).length - 1;
  return (
    <div className="min-w-72 space-y-2 font-mono text-[12px]">
      {steps.map(([at, label], i) =>
        i <= current ? (
          <p key={at} className={`slide-in flex items-center gap-3 ${i < current ? 'text-stone-400' : 'text-ink'}`}>
            {i < current ? (
              <span className="w-3 text-center text-leaf">✓</span>
            ) : (
              <span className="h-1.5 w-3 animate-pulse rounded-full bg-brand-500" />
            )}
            {label}
            {i === current && <span className="animate-pulse">…</span>}
          </p>
        ) : null,
      )}
      <p className="pt-1 text-[10px] uppercase tracking-[0.16em] text-stone-400">AI via OpenRouter · {elapsed}s</p>
    </div>
  );
}

export default function NewProject() {
  const nav = useNavigate();
  const [items, setItems] = useState([]);
  const [brief, setBrief] = useState('');
  const [cart, setCart] = useState([]);
  const [customOn, setCustomOn] = useState(false);
  const [custom, setCustom] = useState('');
  const [phase, setPhase] = useState('compose'); // compose | scoping
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const customRef = useRef(null);

  const [orderId, setOrderId] = useState(null);
  const [title, setTitle] = useState('');
  const [questions, setQuestions] = useState([]);
  const [answers, setAnswers] = useState([]);
  const [draft, setDraft] = useState('');
  const [result, setResult] = useState(null);
  const endRef = useRef(null);

  useEffect(() => {
    api('/api/menu').then((d) => setItems(d.items)).catch((e) => setError(e.message));
  }, []);
  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [answers.length, busy, questions.length, result]);

  const chosen = items.filter((i) => cart.includes(i.id));
  const menuTotal = chosen.reduce((s, i) => s + i.price_cents, 0);
  const hasCustom = customOn && custom.trim().length > 0;
  const briefOk = brief.trim().length >= MIN_BRIEF;
  const customOk = !customOn || custom.trim().length >= 8;
  const cartEmpty = chosen.length === 0 && !hasCustom;
  const blocker = !briefOk
    ? 'Describe your project in step 1'
    : cartEmpty
      ? 'Add at least one dish or the Chef’s special'
      : !customOk
        ? 'Describe your Chef’s special in a few more words'
        : '';

  const toggle = (id) => setCart((c) => (c.includes(id) ? c.filter((x) => x !== id) : [...c, id]));
  const openCustom = () => {
    setCustomOn((v) => !v);
    setTimeout(() => customRef.current?.focus(), 60);
  };

  const submit = async () => {
    if (blocker) return setError(blocker);
    setBusy(true);
    setError('');
    try {
      if (!hasCustom) {
        const d = await api('/api/orders/menu', { method: 'POST', body: { itemIds: cart, projectBrief: brief } });
        window.location.href = d.checkoutUrl;
        return;
      }
      setPhase('scoping');
      const d = await api('/api/orders/custom/scope', {
        method: 'POST',
        body: { projectBrief: brief, customRequest: custom, menuItemIds: cart },
      });
      setOrderId(d.orderId);
      setTitle(d.title);
      setQuestions(d.questions);
      setBusy(false);
    } catch (e) {
      setError(e.message);
      setBusy(false);
      setPhase('compose');
    }
  };

  const answer = async (value) => {
    const v = value.trim();
    if (!v || busy) return;
    const next = [...answers, v];
    setAnswers(next);
    setDraft('');
    if (next.length < questions.length) return;
    setBusy(true);
    setError('');
    try {
      const d = await api('/api/orders/custom/scope', { method: 'POST', body: { orderId, answers: next } });
      setResult(d.order);
    } catch (e) {
      setError(e.message);
      setAnswers(next.slice(0, -1));
    } finally {
      setBusy(false);
    }
  };

  /* ------------------------------------------------------------------ Scoping (AI Q&A) */
  if (phase === 'scoping') {
    const step = answers.length;
    return (
      <div className="mx-auto flex h-full max-w-3xl flex-col px-6 pt-12">
        <div className="mb-8 flex items-end justify-between gap-6">
          <div>
            <p className="eyebrow">The chef has a few questions</p>
            <h1 className="display mt-3 text-6xl">
              {title ? <>{title.split(' ').slice(0, -1).join(' ')} <em className="italic">{title.split(' ').slice(-1)}</em></> : <>One <em className="italic">moment</em></>}
            </h1>
          </div>
          {questions.length > 0 && (
            <span className="font-mono text-sm text-stone-500">
              {String(Math.min(step + 1, questions.length)).padStart(2, '0')} / {String(questions.length).padStart(2, '0')}
            </span>
          )}
        </div>
        <div className="flex min-h-0 flex-1 flex-col border-t border-stone-300">
          <div className="min-h-0 flex-1 space-y-7 overflow-y-auto py-8 pr-2">
            <Me>
              <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-stone-400">My project</p>
              <p className="mt-1">{brief}</p>
              {chosen.length > 0 && (
                <>
                  <p className="mt-3 font-mono text-[10px] uppercase tracking-[0.16em] text-stone-400">From the menu</p>
                  <p className="mt-1">{chosen.map((i) => i.name).join(' · ')}</p>
                </>
              )}
              <p className="mt-3 font-mono text-[10px] uppercase tracking-[0.16em] text-brand-300">Custom</p>
              <p className="mt-1">{custom}</p>
            </Me>
            {!orderId && busy && (
              <Bot>
                <AiProgress steps={QUESTION_STEPS} />
              </Bot>
            )}
            {questions.slice(0, step + 1).map((q, i) => (
              <div key={i} className="space-y-7">
                <Bot>
                  <p className="font-display text-[26px] leading-tight">{q.question}</p>
                  {i === step && !busy && !result && (
                    <div className="mt-4 flex flex-wrap gap-2">
                      {q.suggestions.map((s) => (
                        <button
                          key={s}
                          onClick={() => answer(s)}
                          className="rounded-full border border-stone-300 px-3.5 py-1.5 text-left text-sm text-stone-700 transition duration-300 hover:border-ink hover:bg-ink hover:text-paper"
                        >
                          {s}
                        </button>
                      ))}
                    </div>
                  )}
                </Bot>
                {answers[i] && <Me>{answers[i]}</Me>}
              </div>
            ))}
            {orderId && busy && (
              <Bot>
                <AiProgress steps={QUOTE_STEPS} />
              </Bot>
            )}
            {result && (
              <Bot>
                <div className="ticket print w-full max-w-md px-6 pb-7 pt-8 font-mono text-[12px]">
                  <div className="flex items-baseline justify-between">
                    <span className="font-display text-2xl italic">Your quote</span>
                    <span className="text-stone-500">№ {result.id}</span>
                  </div>
                  <div className="rule-dashed my-4" />
                  <ul className="space-y-2">
                    {result.quote.modules.map((m) => (
                      <li key={m.id} className="flex items-baseline gap-2">
                        <span className={m.optional ? 'text-stone-500' : ''}>
                          {m.name}
                          {m.menu && <span className="ml-1.5 text-[10px] uppercase text-brand-600">menu</span>}
                          {m.optional && <span className="ml-1.5 text-[10px] uppercase text-stone-400">optional</span>}
                        </span>
                        <span className="leader" />
                        <span>{money(m.price_cents)}</span>
                      </li>
                    ))}
                  </ul>
                  <div className="rule-dashed my-4" />
                  <div className="flex items-baseline justify-between">
                    <span className="uppercase tracking-[0.16em]">Total</span>
                    <span className="font-display text-4xl">{money(totalOf(result.quote.modules))}</span>
                  </div>
                  <p className="mt-3 text-[11px] leading-relaxed text-stone-500">A developer is reviewing it now. It appears live in your order the moment they approve.</p>
                </div>
                <button className="btn-primary mt-5" onClick={() => nav(`/client/orders/${result.id}`)}>
                  Open order {result.id} <span aria-hidden>→</span>
                </button>
              </Bot>
            )}
            {error && <p className="font-mono text-xs text-brand-600">{error}</p>}
            <div ref={endRef} />
          </div>
          {orderId && !result && (
            <form
              className="border-t border-stone-300 py-4"
              onSubmit={(e) => {
                e.preventDefault();
                answer(draft);
              }}
            >
              <div className="flex items-center gap-3">
                <input
                  className="w-full border-0 bg-transparent py-2 text-lg outline-none placeholder:text-stone-400"
                  disabled={busy}
                  placeholder="Or type your own answer…"
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                />
                <button className="btn-primary" disabled={busy || !draft.trim()}>Answer →</button>
              </div>
            </form>
          )}
        </div>
      </div>
    );
  }

  /* ------------------------------------------------------------------ Compose: one menu, one cart */
  return (
    <div className="mx-auto grid max-w-[1400px] gap-x-16 gap-y-10 px-6 pb-24 pt-12 lg:grid-cols-[minmax(0,1fr)_380px]">
      <section>
        <p className="eyebrow">New order</p>
        <h1 className="display rise mt-3 text-[clamp(56px,6vw,96px)]">
          What are we <em className="italic text-brand-500">cooking?</em>
        </h1>
        <ol className="mt-8 grid max-w-2xl grid-cols-3 gap-3" aria-label="Progress">
          {[
            ['Describe your project', briefOk],
            ['Pick what you need', !cartEmpty && customOk],
            [hasCustom ? 'Get your quote' : 'Pay & start', false],
          ].map(([label, done], i, arr) => {
            const current = !done && arr.slice(0, i).every(([, d]) => d);
            return (
              <li key={label} className={`rounded-xl border px-4 py-3 transition ${done ? 'border-leaf/40 bg-leaf/10' : current ? 'border-brand-500/60 bg-brand-50' : 'border-stone-200'}`}>
                <span className={`font-mono text-[11px] ${done ? 'text-leaf' : current ? 'text-brand-600' : 'text-stone-400'}`}>
                  {done ? '✓ Done' : `Step ${i + 1}`}
                </span>
                <span className={`mt-0.5 block text-sm ${done || current ? 'text-ink' : 'text-stone-500'}`}>{label}</span>
              </li>
            );
          })}
        </ol>

        {/* 01 — brief */}
        <div className="mt-14 grid gap-6 border-t border-stone-300 pt-6 md:grid-cols-[120px_minmax(0,1fr)]">
          <div>
            <span className="font-mono text-xs text-stone-400">01</span>
            <p className="mt-1 font-display text-2xl leading-none">The brief</p>
            <p className={`mt-2 font-mono text-[10px] uppercase tracking-[0.14em] ${briefOk ? 'text-leaf' : 'text-stone-400'}`}>
              {briefOk ? '✓ Got it' : 'Required'}
            </p>
          </div>
          <div>
            <textarea
              className="min-h-32 w-full resize-y rounded-xl border border-stone-300 bg-surface px-5 py-4 font-display text-[26px] leading-snug text-ink outline-none transition placeholder:text-stone-400 focus:border-brand-500"
              placeholder="e.g. I run a dental clinic and want patients to book appointments online…"
              aria-label="Describe your project"
              value={brief}
              onChange={(e) => setBrief(e.target.value)}
            />
            <div className="mt-3 flex flex-wrap items-center gap-2">
              <span className="text-sm text-stone-500">Need inspiration?</span>
              {BRIEF_EXAMPLES.map(([label, text]) => (
                <button
                  key={label}
                  onClick={() => setBrief(text)}
                  className="rounded-full border border-stone-300 px-3 py-1 text-xs text-stone-600 transition hover:border-ink hover:text-ink"
                >
                  {label}
                </button>
              ))}
              <span className={`ml-auto font-mono text-[11px] ${briefOk ? 'text-leaf' : 'text-stone-400'}`}>{briefOk ? 'Looks good' : `${Math.max(0, MIN_BRIEF - brief.trim().length)} more characters`}</span>
            </div>
          </div>
        </div>

        {/* 02 — the menu */}
        <div className="mt-14 grid gap-6 border-t border-stone-300 pt-6 md:grid-cols-[120px_minmax(0,1fr)]">
          <div>
            <span className="font-mono text-xs text-stone-400">02</span>
            <p className="mt-1 font-display text-2xl leading-none">The menu</p>
            <p className="mt-2 text-xs leading-relaxed text-stone-500">Fixed prices. Tap a dish to add it. Need something else? Add the Chef’s special.</p>
          </div>
          <ul>
            {items.map((it, idx) => {
              const inCart = cart.includes(it.id);
              return (
                <li key={it.id} className="group border-b border-stone-200 first:pt-0">
                  <button
                    onClick={() => toggle(it.id)}
                    aria-label={`${inCart ? 'Remove' : 'Add'} ${it.name}`}
                    className="flex w-full items-start gap-5 py-5 text-left"
                  >
                    <span className="mt-1.5 font-mono text-[11px] text-stone-400">{String(idx + 1).padStart(2, '0')}</span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-baseline gap-3">
                        <span className={`font-display text-[30px] leading-none transition ${inCart ? 'italic text-brand-500' : 'group-hover:italic'}`}>
                          {it.name}
                        </span>
                        <span className="leader" />
                        <span className="font-mono text-lg">{money(it.price_cents)}</span>
                      </span>
                      <span className="mt-2 flex items-start justify-between gap-6">
                        <span className="max-w-md text-sm text-stone-500">{it.description}</span>
                        <span className="shrink-0 font-mono text-[10px] uppercase tracking-[0.14em] text-stone-400">{it.eta_days} days</span>
                      </span>
                    </span>
                    <span className="mt-1 flex shrink-0 flex-col items-center gap-1">
                      <span
                        className={`grid h-10 w-10 place-items-center rounded-full border text-lg transition-all duration-500 ${
                          inCart ? 'rotate-45 border-brand-500 bg-brand-500 text-white' : 'border-stone-300 group-hover:border-ink'
                        }`}
                      >
                        +
                      </span>
                      <span className={`font-mono text-[10px] uppercase tracking-[0.12em] ${inCart ? 'text-brand-600' : 'text-stone-500'}`}>{inCart ? 'Added' : 'Add'}</span>
                    </span>
                  </button>
                </li>
              );
            })}

            {/* Chef's special — custom work, AI-priced, same cart */}
            <li className={`group border-b border-stone-200 ${customOn ? 'bg-surface' : ''} -mx-4 rounded-xl px-4 transition-colors`}>
              <button onClick={openCustom} aria-label="Toggle custom feature" className="flex w-full items-start gap-5 py-5 text-left">
                <span className="mt-1.5 font-mono text-[11px] text-brand-500">✺</span>
                <span className="min-w-0 flex-1">
                  <span className="flex items-baseline gap-3">
                    <span className={`font-display text-[30px] leading-none ${customOn ? 'italic text-brand-500' : 'italic'}`}>Chef’s special</span>
                    <span className="leader" />
                    <span className="font-mono text-xs uppercase tracking-[0.14em] text-stone-500">priced by AI</span>
                  </span>
                  <span className="mt-2 block max-w-md text-sm text-stone-500">
                    Anything that isn’t on the menu. The AI asks a few questions and prices it together with the rest of your order.
                  </span>
                </span>
                <span className="mt-1 flex shrink-0 flex-col items-center gap-1">
                  <span
                    className={`grid h-10 w-10 place-items-center rounded-full border text-lg transition-all duration-500 ${
                      customOn ? 'rotate-45 border-brand-500 bg-brand-500 text-white' : 'border-stone-300 group-hover:border-ink'
                    }`}
                  >
                    +
                  </span>
                  <span className={`font-mono text-[10px] uppercase tracking-[0.12em] ${customOn ? 'text-brand-600' : 'text-stone-500'}`}>{customOn ? 'Added' : 'Add'}</span>
                </span>
              </button>
              {customOn && (
                <div className="slide-in pb-6 pl-10">
                  <textarea
                    ref={customRef}
                    className="min-h-20 w-full resize-none rounded-lg border border-stone-300 bg-paper px-4 py-3 text-base outline-none transition focus:border-ink"
                    placeholder="e.g. An AI chatbot on the website that answers patient FAQs and links to booking"
                    value={custom}
                    onChange={(e) => setCustom(e.target.value)}
                  />
                  <div className="mt-2 flex flex-wrap gap-2">
                    {CUSTOM_EXAMPLES.map((ex) => (
                      <button
                        key={ex}
                        onClick={() => setCustom(ex)}
                        className="rounded-full border border-stone-300 px-3 py-1 text-xs text-stone-600 transition hover:border-ink hover:text-ink"
                      >
                        {ex}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </li>
          </ul>
        </div>
      </section>

      {/* Receipt cart */}
      <aside className="lg:sticky lg:top-24 lg:h-fit">
        <div className="ticket px-7 pb-8 pt-9 font-mono text-[12.5px]">
          <div className="flex items-baseline justify-between">
            <span className="font-display text-3xl italic">Your order</span>
            <span className="text-[11px] text-stone-400">{new Date().toLocaleDateString(undefined, { day: '2-digit', month: 'short' })}</span>
          </div>
          <p className="mt-2 line-clamp-2 text-[11px] leading-relaxed text-stone-500">{briefOk ? brief : '— no brief yet —'}</p>
          <div className="rule-dashed my-5" />
          {cartEmpty ? (
            <p className="py-6 text-center text-[11px] uppercase tracking-[0.2em] text-stone-400">Nothing ordered yet</p>
          ) : (
            <ul className="space-y-2.5">
              {chosen.map((i) => (
                <li key={i.id} className="group flex items-baseline gap-2">
                  <button className="text-stone-500 transition hover:text-brand-500" onClick={() => toggle(i.id)} aria-label={`Remove ${i.name}`}>×</button>
                  <span>{i.name}</span>
                  <span className="leader" />
                  <span>{money(i.price_cents)}</span>
                </li>
              ))}
              {hasCustom && (
                <li className="flex items-baseline gap-2 text-brand-600">
                  <button className="text-brand-400 transition hover:text-brand-700" onClick={() => setCustomOn(false)} aria-label="Remove custom feature">×</button>
                  <span className="min-w-0 truncate">Chef’s special</span>
                  <span className="leader !border-brand-200" />
                  <span>AI</span>
                </li>
              )}
            </ul>
          )}
          <div className="rule-dashed my-5" />
          <div className="flex items-baseline justify-between">
            <span className="uppercase tracking-[0.16em]">{hasCustom ? 'So far' : 'Total'}</span>
            <span className="font-display text-5xl tracking-tight">
              {money(menuTotal)}
              {hasCustom && <span className="ml-1 font-mono text-sm text-stone-500">+</span>}
            </span>
          </div>
          {error && <p className="mt-4 text-[11px] text-brand-600">{error}</p>}
          <button className="btn-primary mt-6 w-full py-3.5 font-sans text-[15px]" disabled={!!blocker || busy} onClick={submit}>
            {busy ? 'One moment…' : hasCustom ? 'Get my quote' : `Pay ${money(menuTotal)}`} <span aria-hidden>→</span>
          </button>
          <p className={`mt-3 text-center font-sans text-[13px] leading-relaxed ${blocker ? 'text-brand-600' : 'text-stone-500'}`}>
            {blocker
              ? `↑ ${blocker}`
              : hasCustom
                ? 'The AI asks 3–4 quick questions, then a developer reviews your quote. Nothing is charged yet.'
                : 'You’ll pay securely on Stripe. Test card: 4242 4242 4242 4242.'}
          </p>
        </div>
      </aside>
    </div>
  );
}
