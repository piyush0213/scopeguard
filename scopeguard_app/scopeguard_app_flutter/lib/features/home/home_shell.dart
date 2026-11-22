import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/payments.dart';
import '../../core/ui.dart';
import '../../core/session.dart';
import '../client/new_project_screen.dart';
import '../orders/order_screen.dart';
import '../orders/orders_screen.dart';
import '../room/join_room_screen.dart';

/// Bottom navigation. Clients: New project / My orders / Scope Room. Developers: Order queue / Scope Room.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final ret = pendingStripeReturn;
    pendingStripeReturn = null;
    if (ret != null) WidgetsBinding.instance.addPostFrameCallback((_) => _handleStripeReturn(ret));
  }

  /// Back from Stripe Checkout: confirm the payment with the server and open the order.
  Future<void> _handleStripeReturn(StripeReturn ret) async {
    if (!mounted || isDev) return;
    setState(() => _tab = 1);
    if (ret.canceled) {
      await forgetPendingPayment(ret.orderId);
      if (mounted) toast(context, 'Payment canceled — nothing was charged.');
    } else {
      try {
        final r = await confirmPayment(ret.orderId, stripeSessionId: ret.sessionId);
        if (mounted) toast(context, r.paid ? 'Payment confirmed — money is in escrow and the scope is locked.' : 'Stripe has not confirmed the payment yet. It will update by itself.');
      } catch (e) {
        if (mounted) toast(context, errorText(e));
      }
    }
    if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: ret.orderId)));
  }

  @override
  Widget build(BuildContext context) {
    final dev = isDev;
    final pages = dev
        ? [const OrdersScreen(), const JoinRoomScreen(embedded: true)]
        : [NewProjectScreen(onCreated: () => setState(() => _tab = 1)), const OrdersScreen(), const JoinRoomScreen(embedded: true)];
    final items = dev
        ? const [
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Order queue'),
            NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Scope Room'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'New project'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'My orders'),
            NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Scope Room'),
          ];
    final tab = _tab.clamp(0, pages.length - 1);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          const Icon(Icons.shield_outlined, color: brand, size: 20),
          const SizedBox(width: 8),
          Text('ScopeGuard', style: display(24)),
          const SizedBox(width: 10),
          Text(dev ? 'KITCHEN' : 'COUNTER', style: mono(10, color: faint, spacing: 2)),
        ]),
        actions: [
          // On phones the name would crowd the title; it is shown only on wider screens.
          if (MediaQuery.of(context).size.width > 520)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: Text(currentUser.value?.name ?? '', style: const TextStyle(color: muted, fontSize: 13))),
            ),
          IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout, size: 20), onPressed: signOut),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, destinations: items, onDestinationSelected: (i) => setState(() => _tab = i)),
    );
  }
}
