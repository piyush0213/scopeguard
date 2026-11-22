import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scopeguard_app_client/scopeguard_app_client.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/payments.dart';
import '../../core/server_clock.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import 'lock_moment_view.dart';

/// The live Scope Room. One streaming connection to Serverpod; every change anyone makes (or that is made
/// on the website) arrives as a fresh RoomState on every phone.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.ticket});
  final RoomTicket ticket;
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  RoomState? _s;
  StreamSubscription<RoomState>? _sub;
  bool _live = false;
  String? _fatal;
  int? _celebrated; // round whose lock wave we already showed
  bool _busy = false;

  RoomTicket get t => widget.ticket;

  @override
  void initState() {
    super.initState();
    serverClock.sync();
    _connect();
  }

  void _connect() {
    _sub?.cancel();
    _sub = client.scopeRoom.watch(t.code, t.token).listen(
      (s) => setState(() {
        _s = s;
        _live = true;
      }),
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _live = false);
        if (e is SgException && e.status == 403) return setState(() => _fatal = e.message);
        Future.delayed(const Duration(seconds: 2), () => mounted ? _connect() : null);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _live = false);
        Future.delayed(const Duration(seconds: 2), () => mounted ? _connect() : null);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _act(Future<void> Function() f) async {
    setState(() => _busy = true);
    await attempt(context, f);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _leave() async {
    await _sub?.cancel();
    try {
      await client.scopeRoom.leave(t.code, t.token);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  String get _joinLink {
    if (kIsWeb && Uri.base.scheme.startsWith('http')) {
      return Uri.base.replace(path: '/', queryParameters: {'room': t.code}, fragment: '').toString();
    }
    return 'Scope Room ${t.code}';
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (_fatal != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_fatal!, style: const TextStyle(color: brand))));
    if (s == null) return const Scaffold(body: Loading());
    final order = jsonDecode(s.orderJson) as Map<String, dynamic>;
    final me = s.members.where((m) => m.id == t.memberId).firstOrNull;
    final here = s.members.where((m) => m.connections > 0).toList();
    final agreedCount = here.where((m) => m.agreedRound == s.room.round).length;
    final iAgreed = me != null && me.agreedRound == s.room.round;
    final isHost = s.room.hostMemberId == t.memberId;
    final items = ((order['quote']?['modules'] as List?) ?? const []).cast<Map>();
    final total = items.where((m) => m['included'] == true || m['optional'] != true).fold<num>(0, (a, m) => a + (m['price_cents'] as num));
    final canToggle = me?.role == 'client' && s.room.status == 'open' && order['paid'] != true;

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Leave room', onPressed: _leave),
          title: Text('Scope Room', style: display(24)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: [
                Icon(Icons.circle, size: 8, color: _live ? leaf : faint),
                const SizedBox(width: 6),
                Text(_live ? 'live' : 'reconnecting…', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
          ],
        ),
        body: Narrow(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
            // Code + QR, then who's here (full width so names fit on phones)
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Eyebrow('${s.room.orderId} · join code'),
                      SelectableText(t.code, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 8)),
                      Text('${s.room.title}', style: const TextStyle(color: muted)),
                    ]),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                      child: QrImageView(data: _joinLink, size: MediaQuery.of(context).size.width < 480 ? 84 : 104, padding: EdgeInsets.zero),
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in s.members)
                    Opacity(
                      opacity: m.connections > 0 ? 1 : 0.35,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: seatColor(m.color).withValues(alpha: 0.14),
                        side: BorderSide(color: seatColor(m.color).withValues(alpha: 0.5)),
                        avatar: Icon(m.agreedRound == s.room.round ? Icons.check_circle : Icons.circle_outlined, size: 16, color: seatColor(m.color)),
                        label: Text('${m.name}${m.id == t.memberId ? ' (you)' : ''} · ${m.role}${m.id == s.room.hostMemberId ? ' ★' : ''}'),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Live bill
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Eyebrow('Live scope · quote v${order['quote']?['version'] ?? 1}'),
                const SizedBox(height: 12),
                for (final m in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(
                        width: 44,
                        child: m['optional'] == true
                            ? Switch(
                                value: m['included'] == true,
                                onChanged: canToggle && !_busy ? (v) => _act(() => client.scopeRoom.toggle(t.code, t.token, '${m['id']}', v)) : null,
                              )
                            : const Icon(Icons.lock_outline, size: 16, color: faint),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LeaderRow(
                          left: '${m['name']}',
                          right: money(m['price_cents'] as num),
                          strike: m['optional'] == true && m['included'] != true,
                          tag: m['optional'] == true ? 'optional' : null,
                        ),
                      ),
                    ]),
                  ),
                const Divider(height: 20),
                Row(children: [
                  const Text('Total', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(money(total), key: ValueKey(total), style: display(36)),
                  ),
                ]),
                if (!canToggle && s.room.status == 'open')
                  Text(me?.role == 'client' ? '' : 'Only the client can switch optional items. Ask them out loud!', style: const TextStyle(color: faint, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),

            if (s.room.status == 'open') ...[
              Text('$agreedCount of ${here.length} here agree', textAlign: TextAlign.center, style: mono(12, color: agreedCount == here.length && here.length > 1 ? leaf : muted)),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: iAgreed ? leaf : brand, foregroundColor: iAgreed ? canvas : Colors.white),
                  onPressed: _busy
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          _act(() => client.scopeRoom.agree(t.code, t.token, !iAgreed));
                        },
                  icon: Icon(iAgreed ? Icons.check : Icons.handshake_outlined),
                  label: Text(iAgreed ? 'You agreed — tap to take it back' : 'I agree to this scope', style: const TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                here.length < 2
                    ? 'Waiting for someone else to join — share the code or QR.'
                    : 'When everyone here agrees, every phone lights up and the scope is agreed in person. Any change to the bill resets the agreement.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: faint, fontSize: 12, height: 1.4),
              ),
            ],

            if (s.room.status == 'agreed' && s.agreement != null) ...[
              Panel(
                accent: leaf,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Eyebrow('Agreed in person', color: leaf),
                  const SizedBox(height: 6),
                  Text('Scope agreed.', style: display(34)),
                  const SizedBox(height: 8),
                  Text(s.agreement!.signers.join(' · '), style: const TextStyle(color: muted, height: 1.4)),
                  const SizedBox(height: 8),
                  Text('quote v${s.agreement!.quoteVersion} · ${money(s.agreement!.totalCents)} · fingerprint ${s.agreement!.fingerprint.substring(0, 12)}…', style: mono(10.5)),
                  const SizedBox(height: 4),
                  const Text('Also posted to the order chat on the website.', style: TextStyle(color: faint, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 12),
              if (me?.role == 'client' && order['paid'] != true)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act(() async {
                            final d = jsonDecode(await client.shop.checkout(token, s.room.orderId, (order['quote']['version'] as num).toInt()));
                            if (mounted) await openCheckout(context, s.room.orderId, d['checkoutUrl'] as String);
                          }),
                  child: Text('Pay ${money(total)} into escrow'),
                ),
              if (order['paid'] == true) const Text('Paid — scope locked. Payment goes to escrow and is released on proof.', textAlign: TextAlign.center, style: TextStyle(color: leaf)),
            ],

            if (s.room.status == 'ended')
              const EmptyNote(title: 'Meeting over', body: 'The host ended this room. The agreement stays on the order.'),

            if (isHost && s.room.status != 'ended') ...[
              const SizedBox(height: 20),
              Row(children: [
                if (s.room.status == 'agreed')
                  Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _act(() => client.scopeRoom.reopen(t.code, t.token)), child: const Text('Re-open for changes'))),
                if (s.room.status == 'agreed') const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _act(() => client.scopeRoom.end(t.code, t.token)), child: const Text('End meeting'))),
              ]),
            ],
          ]),
        ),
      ),
      // Play the lock wave only if the agreement just happened (not for someone joining an old, agreed room).
      if (s.moment != null &&
          s.room.status == 'agreed' &&
          _celebrated != s.room.round &&
          serverClock.now().difference(s.moment!.startAt.toUtc()) < const Duration(seconds: 20))
        Positioned.fill(
          child: LockMomentView(
            moment: s.moment!,
            me: t.memberId,
            members: s.members,
            totalCents: total.toInt(),
            onClose: () => setState(() => _celebrated = s.room.round),
          ),
        ),
    ]);
  }
}
