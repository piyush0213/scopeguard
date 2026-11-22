import '../client.dart';

/// Estimates this device's clock offset from the server (best of a few round trips), so the
/// Scope Room lock wave fires at the same real moment on every phone.
class ServerClock {
  Duration offset = Duration.zero;
  DateTime now() => DateTime.now().toUtc().add(offset);

  Future<void> sync({int samples = 5}) async {
    Duration? best;
    for (var i = 0; i < samples; i++) {
      try {
        final t0 = DateTime.now().toUtc();
        final server = await client.scopeRoom.now();
        final t1 = DateTime.now().toUtc();
        final rtt = t1.difference(t0);
        if (best == null || rtt < best) {
          best = rtt;
          offset = server.toUtc().difference(t0.add(rtt ~/ 2));
        }
      } catch (_) {}
    }
  }
}

final serverClock = ServerClock();
