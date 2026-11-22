import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stripe Checkout session ids per order, so the app can confirm the payment when the user comes back.
final Map<String, String> pendingStripeSessions = {};

/// Opens Stripe Checkout (in the browser) and remembers the session to confirm later.
Future<void> openCheckout(BuildContext context, String orderId, String checkoutUrl) async {
  final m = RegExp(r'cs_(test|live)_[A-Za-z0-9]+').firstMatch(checkoutUrl);
  if (m != null) pendingStripeSessions[orderId] = m.group(0)!;
  await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}
