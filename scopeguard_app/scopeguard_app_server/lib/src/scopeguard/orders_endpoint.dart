import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'sg_api.dart';

/// Shared by clients and developers: one order with its chat, live updates, and Proof-of-Delivery.
class OrdersEndpoint extends Endpoint {
  /// {order, messages, git?}
  Future<String> get(Session session, String token, String orderId) =>
      SgApi.json('GET', '/api/orders/$orderId', token: token);

  Future<String> send(Session session, String token, String orderId, String content) =>
      SgApi.json('POST', '/api/orders/$orderId/messages', token: token, body: {'content': content});

  Future<String> audit(Session session, String token, String orderId) =>
      SgApi.json('POST', '/api/orders/$orderId/proof/audit', token: token);

  Future<String> proofScore(Session session, String token, String devId) =>
      SgApi.json('GET', '/api/proof-score/$devId', token: token);

  /// Live order: emits {order, messages} now and again whenever anything changes, including changes
  /// made on the website, by GitHub pushes, Stripe payments or the Proof auditor.
  Stream<String> watch(Session session, String token, String orderId) {
    late final StreamController<String> out;
    Timer? timer;
    String? last;
    var busy = false;
    Future<void> tick() async {
      if (busy || out.isClosed) return;
      busy = true;
      try {
        final j = await SgApi.json('GET', '/api/orders/$orderId', token: token);
        if (j != last && !out.isClosed) {
          last = j;
          out.add(j);
        }
      } on SgException catch (e) {
        if ((e.status == 401 || e.status == 403 || e.status == 404) && !out.isClosed) {
          out.addError(e);
          await out.close();
        }
      } finally {
        busy = false;
      }
    }

    out = StreamController<String>(
      onListen: () {
        tick();
        timer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
      },
      onCancel: () => timer?.cancel(),
    );
    return out.stream;
  }
}
