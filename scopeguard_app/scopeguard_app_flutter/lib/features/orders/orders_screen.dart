import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import 'order_screen.dart';

/// Clients: "My orders". Developers: the order queue with tabs and their Proof Score.
/// Refreshes every few seconds, so orders made on the website show up here too.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>>? _orders;
  Map<String, dynamic>? _score;
  String? _error;
  int _tab = 0;
  Timer? _timer;

  static final _devTabs = <(String, bool Function(Map))>[
    ('New quotes', (o) => o['status'] == 'ai_draft'),
    ('Negotiating', (o) => o['paid'] != true && ['negotiating', 'awaiting_payment'].contains(o['status'])),
    ('Cooking', (o) => o['paid'] == true && (o['stage'] as num) < 7),
    ('Served', (o) => o['stage'] == 7),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = jsonDecode(isDev ? await client.kitchen.queue(token) : await client.shop.myOrders(token));
      final list = (d['orders'] as List).cast<Map<String, dynamic>>().where((o) => o['status'] != 'scoping').toList();
      if (isDev && _score == null) {
        _score = jsonDecode(await client.orders.proofScore(token, currentUser.value!.userId)) as Map<String, dynamic>;
      }
      if (mounted) setState(() {
        _orders = list;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final dev = isDev;
    final shown = orders == null ? <Map<String, dynamic>>[] : dev ? orders.where(_devTabs[_tab].$2).toList() : orders;
    return RefreshIndicator(
      onRefresh: _load,
      child: Narrow(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
          Text(dev ? 'Order' : 'My', style: display(44)),
          Text(dev ? 'queue' : 'orders', style: display(44, color: brand, style: FontStyle.italic)),
          const SizedBox(height: 16),
          if (dev && _score != null) ...[_ProofScoreCard(score: _score!), const SizedBox(height: 16)],
          if (dev)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < _devTabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${_devTabs[i].$1}  ${orders?.where(_devTabs[i].$2).length ?? 0}'),
                      selected: _tab == i,
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 8),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: brand))),
          if (orders == null && _error == null) const Padding(padding: EdgeInsets.all(40), child: Loading()),
          if (orders != null && shown.isEmpty)
            EmptyNote(title: 'Nothing here yet', body: dev ? 'New orders appear here the moment clients place them.' : 'Start a new project from the first tab.'),
          for (final o in shown) _OrderTile(order: o, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: '${o['id']}'))).then((_) => _load())),
        ]),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (label, color) = statusOf(order);
    final modules = (order['quote']?['modules'] as List?) ?? const [];
    final total = order['paid'] == true
        ? (order['totalCents'] as num? ?? 0)
        : modules.where((m) => m['included'] == true || m['optional'] != true).fold<num>(0, (s, m) => s + (m['price_cents'] as num));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Panel(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${order['id']}${isDev ? ' · ${order['clientName']}' : ''}', style: mono(10.5)),
                const SizedBox(height: 4),
                Text('${order['title']}', style: display(24), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                StatusPill(label, color),
              ]),
            ),
            const SizedBox(width: 10),
            Text(money(total), style: mono(15, color: ink, spacing: 0)),
          ]),
        ),
      ),
    );
  }
}

class _ProofScoreCard extends StatelessWidget {
  const _ProofScoreCard({required this.score});
  final Map<String, dynamic> score;
  @override
  Widget build(BuildContext context) {
    final s = score['score'] as num?;
    return Panel(
      accent: leaf,
      child: Row(children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: (s ?? 0) / 100, strokeWidth: 6, color: leaf, backgroundColor: Colors.white10),
            Text(s == null ? '–' : '$s', style: mono(16, color: ink, spacing: 0)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Proof Score', color: leaf),
            const SizedBox(height: 4),
            Text(
              s == null
                  ? 'No audited work yet — built from verified code, not reviews.'
                  : '${score['proven']} of ${score['criteria']} contract criteria proven in code across ${score['audited']} orders.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text('${money(score['releasedCents'] as num? ?? 0)} earned on proof', style: mono(10)),
          ]),
        ),
      ]),
    );
  }
}
