import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/payments.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../room/room_screen.dart';

/// One order, live (updates from the website, GitHub pushes, Stripe and the Proof auditor appear here).
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _messages = [];
  String? _error;
  StreamSubscription<String>? _sub;
  bool _busy = false;
  final _chat = TextEditingController();
  final _repo = TextEditingController();

  String get _id => widget.orderId;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _sub?.cancel();
    _sub = client.orders.watch(token, _id).listen((j) {
      final d = jsonDecode(j) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _order = d['order'] as Map<String, dynamic>;
        _messages = (d['messages'] as List).cast<Map<String, dynamic>>();
        _error = null;
      });
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() => _error = errorText(e));
      Future.delayed(const Duration(seconds: 3), () => mounted ? _connect() : null);
    }, onDone: () => Future.delayed(const Duration(seconds: 3), () => mounted ? _connect() : null));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _do(Future<void> Function() action, [String? done]) async {
    setState(() => _busy = true);
    final ok = await attempt(context, action);
    if (mounted) {
      setState(() => _busy = false);
      if (ok && done != null) toast(context, done);
    }
  }

  Future<void> _openRoom() async {
    setState(() => _busy = true);
    try {
      final t = await client.scopeRoom.open(token, _id);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(ticket: t)));
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(title: Text(_id, style: mono(13, color: ink))),
      body: o == null
          ? (_error != null ? Center(child: Text(_error!, style: const TextStyle(color: brand))) : const Loading())
          : Narrow(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
                _header(o),
                const SizedBox(height: 16),
                _nextStep(o),
                const SizedBox(height: 16),
                ..._body(o),
                const SizedBox(height: 20),
                _chatPanel(o),
              ]),
            ),
    );
  }

  // ------------------------------------------------------------------ header + next step

  Widget _header(Map o) {
    final (label, color) = statusOf(o);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${o['title']}', style: display(38)),
      const SizedBox(height: 10),
      Row(children: [
        StatusPill(label, color),
        const SizedBox(width: 10),
        Text(isDev ? 'for ${o['clientName']}' : (o['devName'] != null ? 'dev: ${o['devName']}' : ''), style: const TextStyle(color: muted, fontSize: 13)),
        const Spacer(),
        Text(money(o['paid'] == true ? (o['totalCents'] as num) : _total(o)), style: display(30)),
      ]),
    ]);
  }

  num _total(Map o) => _items(o).where((m) => m['included'] == true || m['optional'] != true).fold<num>(0, (s, m) => s + (m['price_cents'] as num));
  List<Map> _items(Map o) => ((o['quote']?['modules'] as List?) ?? const []).cast<Map>();

  Widget _nextStep(Map o) {
    final dev = isDev;
    final stage = (o['stage'] as num?)?.toInt() ?? -1;
    final paid = o['paid'] == true;
    final (String title, String body, bool yourMove) = switch (true) {
      _ when o['status'] == 'ai_draft' && dev => ('Review the AI quote and send it.', 'Approve it as-is below, or edit prices on the website.', true),
      _ when o['status'] == 'ai_draft' => ('A developer is checking your AI quote.', 'Usually a few minutes. Ask anything in the chat below.', false),
      _ when !paid && dev => ('Agree the scope with the client.', 'Open a Scope Room in the meeting so everyone agrees on their own phone.', true),
      _ when !paid => ('Review your bill, then pay.', 'Switch optional items off to save money, or open a Scope Room to agree it together in the meeting.', true),
      _ when stage == 0 && dev => ('New paid order — accept it.', 'Connect the GitHub repo and accept to start the build.', true),
      _ when stage == 0 => ('Payment received.', 'A developer will accept your order shortly.', false),
      _ when stage < 6 && dev => ('Build it — every push is audited.', 'Each item\'s escrow is released when the auditor proves it in your code.', true),
      _ when stage < 6 => ('Your software is being built.', 'Watch items unlock in the Proof Vault as the code proves them.', false),
      _ when stage == 6 && !dev => ('Delivered — please confirm.', 'Check the work, then accept delivery.', true),
      _ when stage == 6 => ('Waiting for the client to accept.', 'Nothing to do right now.', false),
      _ => ('All done.', 'This order is complete.', false),
    };
    return Panel(
      accent: yourMove ? brand : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: yourMove ? brand : raised,
          child: Icon(yourMove ? Icons.arrow_forward : Icons.hourglass_top, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow('What happens next · ${yourMove ? 'your move' : 'in progress'}', color: yourMove ? brand : faint),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(body, style: const TextStyle(color: muted, fontSize: 13, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------------ main body by state

  List<Widget> _body(Map o) {
    final dev = isDev;
    final paid = o['paid'] == true;
    final stage = (o['stage'] as num?)?.toInt() ?? -1;
    final out = <Widget>[];

    if (!paid) {
      out.add(_bill(o, editable: !dev && ['negotiating', 'awaiting_payment'].contains(o['status'])));
      out.add(const SizedBox(height: 14));
      out.add(_scopeRoomCta());
      if (dev && o['status'] == 'ai_draft') {
        out.add(const SizedBox(height: 12));
        out.add(FilledButton(
          onPressed: _busy ? null : () => _do(() => client.kitchen.approveQuote(token, '${o['quote']['id']}'), 'Quote sent to the client'),
          child: const Text('Approve & send to client'),
        ));
      }
      if (!dev && ['negotiating', 'awaiting_payment'].contains(o['status'])) {
        out.add(const SizedBox(height: 12));
        out.add(FilledButton(
          onPressed: _busy
              ? null
              : () => _do(() async {
                    final d = jsonDecode(await client.shop.checkout(token, _id, (o['quote']['version'] as num).toInt()));
                    if (mounted) await openCheckout(context, _id, d['checkoutUrl'] as String);
                  }),
          child: Text('Accept & pay ${money(_total(o))}'),
        ));
        if (pendingStripeSessions[_id] != null) {
          out.add(TextButton(
            onPressed: _busy
                ? null
                : () => _do(() async {
                      final d = jsonDecode(await client.shop.verifyPayment(token, pendingStripeSessions[_id]!));
                      if (d['settled'] != true) throw Exception('Payment not completed yet (${d['reason'] ?? 'open Stripe and finish paying'})');
                      pendingStripeSessions.remove(_id);
                    }, 'Payment confirmed — scope locked'),
            child: const Text('I paid on Stripe — confirm payment', style: TextStyle(color: leaf)),
          ));
        }
        out.add(const _EscrowNote());
      }
      return out;
    }

    out.add(_tracker(o));
    out.add(const SizedBox(height: 14));
    if (dev && stage <= 1) {
      out.add(_repoPanel(o));
      out.add(const SizedBox(height: 14));
    }
    if (dev && stage == 0) {
      out.add(FilledButton(onPressed: _busy ? null : () => _do(() => client.kitchen.acceptOrder(token, _id), 'Order accepted'), child: const Text('Accept order')));
      out.add(const SizedBox(height: 14));
    }
    if (!dev && stage == 6) {
      out.add(FilledButton(
        style: FilledButton.styleFrom(backgroundColor: leaf, foregroundColor: canvas),
        onPressed: _busy ? null : () => _do(() => client.shop.acceptDelivery(token, _id), 'Delivery accepted — thank you!'),
        child: const Text('Accept delivery'),
      ));
      out.add(const SizedBox(height: 14));
    }
    out.add(_proofVault(o));
    return out;
  }

  Widget _bill(Map o, {required bool editable}) {
    final items = _items(o);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow('The bill · quote v${o['quote']?['version'] ?? 1}'),
        const SizedBox(height: 12),
        for (final m in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              if (m['optional'] == true)
                SizedBox(
                  width: 40,
                  child: Switch(
                    value: m['included'] == true,
                    onChanged: editable && !_busy ? (v) => _do(() => client.shop.toggle(token, _id, '${m['id']}', v)) : null,
                  ),
                )
              else
                const SizedBox(width: 40, child: Icon(Icons.lock_outline, size: 16, color: faint)),
              const SizedBox(width: 8),
              Expanded(
                child: LeaderRow(
                  left: '${m['name']}',
                  right: money(m['price_cents'] as num),
                  strike: m['optional'] == true && m['included'] != true,
                  tag: m['menu'] == true ? 'menu' : (m['optional'] == true ? 'optional' : null),
                ),
              ),
            ]),
          ),
        const Divider(height: 24),
        LeaderRow(left: 'Total', right: money(_total(o))),
      ]),
    );
  }

  Widget _scopeRoomCta() => Panel(
        accent: cyan,
        child: Row(children: [
          const Icon(Icons.groups_2_outlined, color: cyan),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('In a meeting? Open a Scope Room: everyone joins from their phone, sees the bill change live and agrees together.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
          ),
          TextButton(onPressed: _busy ? null : _openRoom, child: const Text('Open', style: TextStyle(color: cyan, fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _tracker(Map o) {
    final stage = (o['stage'] as num?)?.toInt() ?? 0;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Live build tracker · GitHub'),
        const SizedBox(height: 14),
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(
                i < stage || stage == 7 ? Icons.check_circle : (i == stage ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                size: 18,
                color: i < stage || stage == 7 ? leaf : (i == stage ? (o['ciFailed'] == true ? brand : cyan) : faint),
              ),
              const SizedBox(width: 10),
              Text(stages[i].$2, style: TextStyle(color: i <= stage ? ink : faint, fontWeight: i == stage ? FontWeight.w600 : null)),
            ]),
          ),
        if (o['repoFullName'] != null) Text('repo ${o['repoFullName']} · branch ${o['branchName']}', style: mono(10)),
        if (o['prUrl'] != null || o['previewUrl'] != null)
          Wrap(spacing: 8, children: [
            if (o['prUrl'] != null) TextButton(onPressed: () => launchUrl(Uri.parse('${o['prUrl']}')), child: const Text('Pull request ↗')),
            if (o['previewUrl'] != null) TextButton(onPressed: () => launchUrl(Uri.parse('${o['previewUrl']}')), child: const Text('Preview ↗')),
          ]),
      ]),
    );
  }

  Widget _repoPanel(Map o) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('GitHub repo'),
          const SizedBox(height: 8),
          if (o['repoFullName'] != null)
            Text('Connected: ${o['repoFullName']}${o['repoSync']?['error'] != null ? '\n${o['repoSync']['error']}' : ''}', style: const TextStyle(color: muted))
          else
            Row(children: [
              Expanded(child: TextField(controller: _repo, decoration: const InputDecoration(hintText: 'https://github.com/you/repo'))),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _do(() => client.kitchen.connectRepo(token, _id, _repo.text.trim()), 'Repo connected'),
                child: const Text('Connect'),
              ),
            ]),
        ]),
      );

  Widget _proofVault(Map o) {
    final proof = (o['proof'] as Map?) ?? const {};
    final criteria = (proof['criteria'] as Map?) ?? const {};
    final audit = proof['audit'] as Map?;
    final results = (audit?['results'] as Map?) ?? const {};
    final escrow = (proof['escrow'] as Map?) ?? const {};
    final items = _items(o).where((m) => m['included'] == true || m['optional'] != true).toList();
    final total = items.fold<num>(0, (s, m) => s + (m['price_cents'] as num));
    final released = items.where((m) => escrow[m['id']]?['state'] == 'released').fold<num>(0, (s, m) => s + (m['price_cents'] as num));
    final working = proof['status'] == 'compiling' || proof['status'] == 'auditing';
    return Panel(
      accent: leaf,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Eyebrow('Proof-of-Delivery escrow', color: leaf)),
          TextButton(
            onPressed: _busy || working || o['repoFullName'] == null ? null : () => _do(() => client.orders.audit(token, _id), 'Audit started'),
            child: Text(working ? 'Auditing…' : '↻ Audit latest commit'),
          ),
        ]),
        Text('Paid on proof, not promises', style: display(26)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: total == 0 ? 0 : released / total, minHeight: 10, color: leaf, backgroundColor: amber.withValues(alpha: 0.25)),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text('${money(released)} released', style: mono(11, color: leaf)),
          const Spacer(),
          Text('${money(total - released)} ${o['stage'] == 7 ? 'refund due' : 'held'}', style: mono(11, color: amber)),
        ]),
        const SizedBox(height: 8),
        Text(
          working
              ? '${proof['progress'] ?? 'Working…'}'
              : proof['status'] == 'error'
                  ? 'Audit failed: ${proof['error']}'
                  : audit != null
                      ? 'Last audit ${'${audit['sha']}'.substring(0, 7)} · read ${audit['filesRead']} files. ${audit['summary'] ?? ''}'
                      : o['repoFullName'] == null
                          ? 'Audits start once the developer connects the GitHub repo.'
                          : 'Waiting for the first commit…',
          style: const TextStyle(color: muted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 8),
        for (final m in items)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Icon(escrow[m['id']]?['state'] == 'released' ? Icons.lock_open : Icons.shield_outlined,
                  color: escrow[m['id']]?['state'] == 'released' ? leaf : amber),
              title: LeaderRow(left: '${m['name']}', right: money(m['price_cents'] as num)),
              subtitle: Text(
                escrow[m['id']]?['state'] == 'released'
                    ? 'Released'
                    : '${((criteria[m['id']] as List?) ?? const []).where((c) => results[c['id']]?['status'] == 'proven').length}/${((criteria[m['id']] as List?) ?? const []).length} criteria proven',
                style: mono(10, color: escrow[m['id']]?['state'] == 'released' ? leaf : faint),
              ),
              children: [
                for (final c in ((criteria[m['id']] as List?) ?? const []))
                  _Criterion(text: '${c['text']}', result: results[c['id']] as Map?),
              ],
            ),
          ),
      ]),
    );
  }

  // ------------------------------------------------------------------ chat

  Widget _chatPanel(Map o) {
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Negotiation & updates'),
        const SizedBox(height: 10),
        if (_messages.isEmpty) const Text('No messages yet. They arrive here live.', style: TextStyle(color: muted)),
        for (final m in _messages.reversed.take(40).toList().reversed) _Message(m: m, mine: m['senderId'] == currentUser.value?.userId, orderId: _id),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _chat, decoration: const InputDecoration(hintText: 'Ask a question or request a change…'), onSubmitted: (_) => _send())),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _send, icon: const Icon(Icons.send, size: 18), style: IconButton.styleFrom(backgroundColor: brand)),
        ]),
      ]),
    );
  }

  Future<void> _send() async {
    final t = _chat.text.trim();
    if (t.isEmpty) return;
    _chat.clear();
    await attempt(context, () => client.orders.send(token, _id, t));
  }
}

class _EscrowNote extends StatelessWidget {
  const _EscrowNote();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Your money waits in escrow. Each item is paid to the developer only when the AI auditor finds it working in the code, with file and line as evidence. Anything never proven is refunded.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),
      );
}

class _Criterion extends StatelessWidget {
  const _Criterion({required this.text, required this.result});
  final String text;
  final Map? result;
  @override
  Widget build(BuildContext context) {
    final st = '${result?['status'] ?? 'pending'}';
    final color = switch (st) { 'proven' => leaf, 'partial' => amber, _ => faint };
    final ev = result?['evidence'] as Map?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(st == 'proven' ? Icons.check : (st == 'partial' ? Icons.timelapse : Icons.radio_button_unchecked), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
        ]),
        if (result?['note'] != null)
          Padding(padding: const EdgeInsets.only(left: 24, top: 2), child: Text('${result!['note']}', style: const TextStyle(color: muted, fontSize: 12, height: 1.35))),
        if (ev != null)
          Container(
            margin: const EdgeInsets.only(left: 24, top: 6),
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: leaf.withValues(alpha: 0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${ev['file']}:${ev['lineStart']}', style: mono(10.5, color: leaf, spacing: 0)),
              const SizedBox(height: 4),
              Text('${ev['snippet']}', style: mono(10.5, color: muted, spacing: 0), maxLines: 8, overflow: TextOverflow.ellipsis),
            ]),
          ),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.m, required this.mine, required this.orderId});
  final Map m;
  final bool mine;
  final String orderId;
  @override
  Widget build(BuildContext context) {
    final system = m['senderRole'] == 'system';
    final addon = m['type'] == 'scope_addon';
    final meta = (m['metadata'] as Map?) ?? const {};
    if (system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('${m['content']}', style: const TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: mine ? ink : raised,
          borderRadius: BorderRadius.circular(16),
          border: addon ? Border.all(color: brand) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Text('${m['senderName']}', style: mono(10, color: brand)),
          Text('${m['content']}', style: TextStyle(color: mine ? canvas : ink, height: 1.4)),
          if (addon && !isDev && meta['status'] == 'offered')
            Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(
                onPressed: () => attempt(context, () async {
                  final d = jsonDecode(await client.shop.payAddon(token, orderId, '${m['id']}'));
                  if (context.mounted) await openCheckout(context, orderId, d['checkoutUrl'] as String);
                }),
                child: Text('Pay & add ${money(meta['priceCents'] as num? ?? 0)}'),
              ),
              TextButton(onPressed: () => attempt(context, () => client.shop.skipAddon(token, orderId, '${m['id']}')), child: const Text('Skip')),
            ]),
          if (addon && meta['status'] != 'offered') Text('${meta['status']}'.toUpperCase(), style: mono(9, color: leaf)),
        ]),
      ),
    );
  }
}
