import 'package:serverpod/serverpod.dart';

import 'sg_api.dart';

/// The client side of ScopeGuard: the menu, ordering, AI scoping, the bill and payment.
/// Results are ScopeGuard's own JSON (the same shape the website renders).
class ShopEndpoint extends Endpoint {
  Future<String> menu(Session session, String token) => SgApi.json('GET', '/api/menu', token: token);

  Future<String> myOrders(Session session, String token) => SgApi.json('GET', '/api/client/orders', token: token);

  /// Menu-only cart: creates the order and returns {orderId, checkoutUrl}.
  /// [returnUrl] is the app's own address, so Stripe sends the payer back into the app.
  Future<String> orderFromMenu(Session session, String token, String projectBrief, List<String> itemIds, {String? returnUrl}) =>
      SgApi.json('POST', '/api/orders/menu',
          token: token, body: {'projectBrief': projectBrief, 'itemIds': itemIds, 'returnUrl': returnUrl});

  /// Custom work (plus any menu items): returns {orderId, title, questions:[{question, suggestions}]}.
  Future<String> startScoping(Session session, String token, String projectBrief, String customRequest, List<String> menuItemIds) =>
      SgApi.json('POST', '/api/orders/custom/scope',
          token: token, body: {'projectBrief': projectBrief, 'customRequest': customRequest, 'menuItemIds': menuItemIds});

  /// Answers to the AI's questions: returns {order} with the AI-drafted quote (a developer reviews it next).
  Future<String> answerScoping(Session session, String token, String orderId, List<String> answers) =>
      SgApi.json('POST', '/api/orders/custom/scope', token: token, body: {'orderId': orderId, 'answers': answers});

  /// Switch an optional item on or off on the live bill.
  Future<String> toggle(Session session, String token, String orderId, String moduleId, bool included) =>
      SgApi.json('PATCH', '/api/orders/$orderId/toggles', token: token, body: {
        'modules': [
          {'id': moduleId, 'included': included}
        ]
      });

  /// Returns {checkoutUrl, scopeHash}. The Stripe session id is part of the URL; pass it to [verifyPayment].
  /// [returnUrl] is the app's own address, so Stripe sends the payer back into the app.
  Future<String> checkout(Session session, String token, String orderId, int quoteVersion, {String? returnUrl}) =>
      SgApi.json('POST', '/api/orders/$orderId/checkout',
          token: token, body: {'quoteVersion': quoteVersion, 'returnUrl': returnUrl});

  /// Confirms a Stripe payment server-side (works without webhooks).
  Future<String> verifyPayment(Session session, String token, String stripeSessionId) =>
      SgApi.json('POST', '/api/payments/verify', token: token, body: {'sessionId': stripeSessionId});

  Future<String> payAddon(Session session, String token, String orderId, String addonId, {String? returnUrl}) =>
      SgApi.json('POST', '/api/orders/$orderId/addons/$addonId/pay', token: token, body: {'returnUrl': returnUrl});

  /// Asks Stripe about this order's open checkouts and settles any that are paid. Returns {settled, reason?, order}.
  /// Needs no Stripe session id, so it works after the app was reloaded.
  Future<String> syncPayment(Session session, String token, String orderId) =>
      SgApi.json('POST', '/api/orders/$orderId/payments/sync', token: token);

  Future<String> skipAddon(Session session, String token, String orderId, String addonId) =>
      SgApi.json('POST', '/api/orders/$orderId/addons/$addonId/skip', token: token);

  Future<String> acceptDelivery(Session session, String token, String orderId) =>
      SgApi.json('POST', '/api/orders/$orderId/client-accept', token: token);
}
