import { useEffect, useState } from 'react';
import { api, money } from '../lib/api.js';

export function ModifyOrderModal({ order, isOpen, onClose, onUpdated }) {
  const [allItems, setAllItems] = useState([]);
  const [selectedItemIds, setSelectedItemIds] = useState([]);
  const [customText, setCustomText] = useState('');
  const [briefText, setBriefText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  // Extract currently active menu item IDs from order
  useEffect(() => {
    if (!isOpen || !order) return;
    setError('');

    // Fetch catalog menu items
    api('/api/menu')
      .then((d) => setAllItems(d.items || []))
      .catch(() => {});

    const menuIds = (order.quote?.modules || [])
      .filter((m) => m.menu)
      .map((m) => m.id.replace(/^menu-/, ''));

    setSelectedItemIds(menuIds.length ? menuIds : order.scoping?.menuItemIds || []);
    setCustomText(order.scoping?.custom || '');
    setBriefText(order.scoping?.idea || order.quote?.brief?.summary || '');
  }, [isOpen, order]);

  if (!isOpen || !order) return null;

  const isPaid = !!order.paid;
  const lockedMenuIds = new Set(
    isPaid
      ? (order.quote?.modules || []).filter((m) => m.menu).map((m) => m.id.replace(/^menu-/, ''))
      : []
  );

  const toggleItem = (id) => {
    if (lockedMenuIds.has(id)) return; // Already locked in paid build
    setSelectedItemIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  // Calculate live preview totals
  const currentTotal = order.paid ? order.totalCents : (order.quote?.modules || []).reduce((s, m) => s + (m.included || !m.optional ? m.price_cents : 0), 0);
  
  let newTotal = 0;
  let deltaCents = 0;

  if (!isPaid) {
    const selectedCatalog = allItems.filter((i) => selectedItemIds.includes(i.id));
    const menuSum = selectedCatalog.reduce((s, i) => s + i.price_cents, 0);
    const existingCustomSum = (order.quote?.modules || []).filter((m) => !m.menu).reduce((s, m) => s + m.price_cents, 0);
    const customSum = customText.trim().length >= 8 ? (existingCustomSum || 35000) : 0;
    newTotal = menuSum + customSum;
    deltaCents = newTotal - currentTotal;
  } else {
    // For paid order, calculate addition
    const addedItems = allItems.filter((i) => selectedItemIds.includes(i.id) && !lockedMenuIds.has(i.id));
    const addedMenuSum = addedItems.reduce((s, i) => s + i.price_cents, 0);
    const customSum = customText.trim().length >= 8 ? 35000 : 0;
    deltaCents = addedMenuSum + customSum;
    newTotal = currentTotal + deltaCents;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError('');

    try {
      const payload = {
        menuItemIds: selectedItemIds,
        customRequest: customText.trim(),
        projectBrief: briefText.trim(),
      };

      const res = await api(`/api/orders/${order.id}/modify`, {
        method: 'PATCH',
        body: payload,
      });

      if (res.order) onUpdated?.(res.order);
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to update order');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/80 backdrop-blur-md transition-opacity"
        onClick={() => !busy && onClose()}
      />

      {/* Modal Dialog */}
      <div className="modal-pop relative flex max-h-[90vh] w-full max-w-2xl flex-col rounded-3xl border border-white/10 bg-[#0f111a] shadow-2xl shadow-black/90">
        {/* Header */}
        <div className="flex items-start justify-between border-b border-white/10 px-6 py-5">
          <div>
            <div className="flex items-center gap-3 font-mono text-[11px] uppercase tracking-[0.18em] text-brand-400">
              <span className="flex h-2 w-2 rounded-full bg-brand-500 animate-pulse" />
              <span>{isPaid ? 'Active Scope Modification' : 'Modify Order & Scope'}</span>
              <span className="text-stone-500">·</span>
              <span className="text-stone-300">№ {order.id}</span>
            </div>
            <h2 className="display mt-1 text-3xl text-white">
              {isPaid ? <>Add to your <em className="italic text-brand-400">build</em></> : <>Update your <em className="italic">order</em></>}
            </h2>
            <p className="mt-1 text-xs text-stone-400">
              {isPaid
                ? 'Select new menu items or describe custom additions. An add-on ticket will be created.'
                : 'Add or remove features and edit your brief. Your bill and quote update live.'}
            </p>
          </div>
          <button
            onClick={onClose}
            disabled={busy}
            className="rounded-full border border-white/10 bg-white/5 p-2 text-stone-400 transition hover:bg-white/10 hover:text-white"
            aria-label="Close"
          >
            ✕
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex min-h-0 flex-1 flex-col overflow-y-auto px-6 py-5 space-y-6">
          {error && (
            <div className="rounded-xl border border-brand-500/30 bg-brand-500/10 p-3.5 font-mono text-xs text-brand-300">
              ⚠ {error}
            </div>
          )}

          {/* Section 1: Menu Items Selection */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <label className="font-mono text-xs uppercase tracking-[0.16em] text-stone-300">
                01 Menu Catalog Items
              </label>
              <span className="text-[11px] text-stone-400">
                {selectedItemIds.length} item{selectedItemIds.length === 1 ? '' : 's'} in order
              </span>
            </div>

            <div className="grid gap-2.5 sm:grid-cols-2">
              {allItems.map((item) => {
                const isSelected = selectedItemIds.includes(item.id);
                const isLocked = lockedMenuIds.has(item.id);

                return (
                  <div
                    key={item.id}
                    onClick={() => !isLocked && toggleItem(item.id)}
                    className={`group relative flex cursor-pointer flex-col justify-between rounded-xl border p-4 transition-all duration-200 ${
                      isLocked
                        ? 'border-emerald-500/30 bg-emerald-500/[0.04] opacity-90 cursor-default'
                        : isSelected
                          ? 'border-brand-500/50 bg-brand-500/[0.08] shadow-md shadow-brand-500/10'
                          : 'border-white/5 bg-white/[0.02] hover:border-white/15 hover:bg-white/[0.04]'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5 font-medium text-sm text-white">
                          <span>{item.emoji}</span>
                          <span className="truncate">{item.name}</span>
                        </div>
                        <p className="mt-1 text-xs leading-relaxed text-stone-400 line-clamp-2">
                          {item.description}
                        </p>
                      </div>
                      <span className="font-mono text-xs font-semibold text-white whitespace-nowrap">
                        {money(item.price_cents)}
                      </span>
                    </div>

                    <div className="mt-3 flex items-center justify-between border-t border-white/5 pt-2">
                      <span className="font-mono text-[10px] uppercase tracking-wider text-stone-400">
                        {item.eta_days}d delivery
                      </span>
                      <span
                        className={`font-mono text-[10px] uppercase tracking-[0.14em] px-2 py-0.5 rounded-full ${
                          isLocked
                            ? 'bg-emerald-500/20 text-emerald-300 font-semibold'
                            : isSelected
                              ? 'bg-brand-500 text-white'
                              : 'bg-white/5 text-stone-400 group-hover:text-white'
                        }`}
                      >
                        {isLocked ? '✓ In Build' : isSelected ? '✓ Selected' : '+ Add'}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Section 2: Custom Requirements */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="font-mono text-xs uppercase tracking-[0.16em] text-stone-300">
                02 Custom Feature / Special Requests
              </label>
              <span className="text-[11px] text-brand-400">AI-scoped & priced</span>
            </div>
            <textarea
              rows={2}
              value={customText}
              onChange={(e) => setCustomText(e.target.value)}
              placeholder="e.g. Add WhatsApp appointment reminders, patient history export, or custom dashboard"
              className="w-full rounded-xl border border-white/10 bg-white/[0.03] p-3 text-sm text-white placeholder:text-stone-500 focus:border-brand-500 focus:outline-none"
            />
            <p className="mt-1 font-mono text-[10px] text-stone-500">
              Leave blank if no custom additions are required.
            </p>
          </div>

          {/* Section 3: Brief / Notes (Pre-pay only) */}
          {!isPaid && (
            <div>
              <label className="font-mono text-xs uppercase tracking-[0.16em] text-stone-300 mb-2 block">
                03 Project Brief Summary
              </label>
              <textarea
                rows={2}
                value={briefText}
                onChange={(e) => setBriefText(e.target.value)}
                placeholder="Short description of your project and goals"
                className="w-full rounded-xl border border-white/10 bg-white/[0.03] p-3 text-sm text-white placeholder:text-stone-500 focus:border-brand-500 focus:outline-none"
              />
            </div>
          )}

          {/* Live Price Delta HUD Bar */}
          <div className="rounded-2xl border border-white/10 bg-black/40 p-4">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-stone-400">
                  {isPaid ? 'Add-on Cost Adjustment' : 'Adjusted Total'}
                </p>
                <div className="mt-1 flex items-baseline gap-3">
                  <span className="font-display text-3xl font-normal text-white">
                    {isPaid ? money(deltaCents) : money(newTotal)}
                  </span>
                  {deltaCents !== 0 && (
                    <span
                      className={`font-mono text-xs px-2 py-0.5 rounded-full font-semibold ${
                        deltaCents > 0
                          ? 'bg-brand-500/20 text-brand-300'
                          : 'bg-emerald-500/20 text-emerald-300'
                      }`}
                    >
                      {deltaCents > 0 ? `+${money(deltaCents)}` : money(deltaCents)}
                    </span>
                  )}
                </div>
              </div>

              <div className="text-right font-mono text-[11px] text-stone-400">
                <p>Base order: {money(currentTotal)}</p>
                <p className="text-stone-300">
                  {isPaid ? 'Direct add-on ticket' : 'Instantly synchronized'}
                </p>
              </div>
            </div>
          </div>

          {/* Footer Actions */}
          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              type="button"
              disabled={busy}
              onClick={onClose}
              className="btn-ghost px-5 py-2.5 text-xs uppercase tracking-wider"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={busy}
              className="btn-primary px-6 py-2.5 text-xs font-semibold uppercase tracking-wider"
            >
              {busy ? 'Saving changes…' : isPaid ? 'Create Add-on & Update Build →' : 'Save & Update Bill →'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
