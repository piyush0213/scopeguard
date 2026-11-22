import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'sg_api.dart';

/// The developer side ("the kitchen"): order queue, quote approval and revisions, accepting orders,
/// linking the GitHub repo and sending priced add-ons.
class KitchenEndpoint extends Endpoint {
  Future<String> queue(Session session, String token) => SgApi.json('GET', '/api/dev/orders', token: token);

  /// Approves the AI-drafted quote as-is and sends it to the client.
  Future<String> approveQuote(Session session, String token, String quoteId) =>
      SgApi.json('PATCH', '/api/quotes/$quoteId/approve', token: token, body: {});

  Future<String> reprice(Session session, String token, String quoteId, String moduleId, int priceCents, String note) async {
    final orderId = await _orderIdOfQuote(token, quoteId);
    final d = await SgApi.call('GET', '/api/orders/$orderId', token: token);
    final modules = [
      for (final m in (d['order']['quote']['modules'] as List))
        m['id'] == moduleId ? {...(m as Map), 'price_cents': priceCents} : m
    ];
    return SgApi.json('PATCH', '/api/quotes/$quoteId/revise', token: token, body: {'modules': modules, 'note': note});
  }

  Future<String> acceptOrder(Session session, String token, String orderId) =>
      SgApi.json('POST', '/api/orders/$orderId/accept', token: token);

  Future<String> connectRepo(Session session, String token, String orderId, String repoUrl) =>
      SgApi.json('POST', '/api/orders/$orderId/repo', token: token, body: {'url': repoUrl});

  Future<String> offerAddon(Session session, String token, String orderId, String title, String description, int priceCents) =>
      SgApi.json('POST', '/api/orders/$orderId/addons',
          token: token, body: {'title': title, 'description': description, 'priceCents': priceCents});

  Future<String> _orderIdOfQuote(String token, String quoteId) async {
    final q = await SgApi.call('GET', '/api/dev/orders', token: token);
    for (final o in (q['orders'] as List)) {
      if (o['quote']?['id'] == quoteId) return '${o['id']}';
    }
    throw SgException(message: 'Quote not found', status: 404);
  }
}
