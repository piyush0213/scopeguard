import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../client.dart';
import 'session.dart';

// Stripe Checkout inside the app's flow:
//  * Web: Stripe opens in the SAME tab (phone browsers block pop-ups opened after a network call) and sends the payer
//    back to this app with ?paid=<order>&session_id=…, which confirms the payment and opens the order.
//  * Android/iOS: Stripe opens in an in-app browser; when the app comes back to the front it confirms the payment.
//  * The server also confirms it by itself (Stripe webhook + checks while the order is open), so the developer sees
//    the paid order even if the payer never returns.

/// Where Stripe sends the payer back: this web app. Native apps use the server default and confirm on resume.
String? get stripeReturnUrl => kIsWeb ? '${Uri.base.origin}/' : null;

/// Orders with a Stripe checkout started on this device. Kept across reloads.
final pendingPayments = ValueNotifier<Set<String>>(<String>{});
const _pendingKey = 'sg_pending_payments';

Future<void> loadPendingPayments() async {
  final prefs = await SharedPreferences.getInstance();
  pendingPayments.value = (prefs.getStringList(_pendingKey) ?? const <String>[]).toSet();
}

Future<void> _setPending(Set<String> next) async {
  pendingPayments.value = next;
  (await SharedPreferences.getInstance()).setStringList(_pendingKey, next.toList());
}

/// Opens Stripe Checkout for [orderId].
Future<void> openCheckout(BuildContext context, String orderId, String checkoutUrl) async {
  await _setPending({...pendingPayments.value, orderId});
  final uri = Uri.parse(checkoutUrl);
  if (kIsWeb) {
    await launchUrl(uri, webOnlyWindowName: '_self');
  } else {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Asks the server (which asks Stripe) whether [orderId] is paid, and locks the scope if so.
Future<({bool paid, String? reason})> confirmPayment(String orderId, {String? stripeSessionId}) async {
  Map<String, dynamic> d;
  if (stripeSessionId != null && stripeSessionId.startsWith('cs_')) {
    d = jsonDecode(await client.shop.verifyPayment(token, stripeSessionId)) as Map<String, dynamic>;
  } else {
    d = jsonDecode(await client.shop.syncPayment(token, orderId)) as Map<String, dynamic>;
  }
  final paid = d['settled'] == true || (d['order'] is Map && d['order']['paid'] == true);
  if (paid) await _setPending({...pendingPayments.value}..remove(orderId));
  return (paid: paid, reason: d['reason'] as String?);
}

Future<void> forgetPendingPayment(String orderId) => _setPending({...pendingPayments.value}..remove(orderId));

/// The payer just came back from Stripe to the web app.
class StripeReturn {
  const StripeReturn(this.orderId, this.sessionId, {required this.canceled});
  final String orderId;
  final String? sessionId;
  final bool canceled;
}

/// Read once at start-up; the home screen handles it after sign-in is restored.
StripeReturn? pendingStripeReturn;

void readStripeReturn() {
  if (!kIsWeb) return;
  final q = Uri.base.queryParameters;
  final paid = q['paid'], canceled = q['canceled'];
  if (paid == null && canceled == null) return;
  pendingStripeReturn = paid != null ? StripeReturn(paid, q['session_id'], canceled: false) : StripeReturn(canceled!, null, canceled: true);
}

/// Drops the Stripe parameters from the address bar (call once the app is running), so a reload doesn't repeat it.
void clearStripeReturnFromUrl() {
  if (kIsWeb) SystemNavigator.routeInformationUpdated(uri: Uri(path: '/'), replace: true);
}
