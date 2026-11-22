import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../generated/protocol.dart';

/// Talks to the ScopeGuard core API (the same one the website uses), so orders, quotes, payments,
/// GitHub tracking and Proof-of-Delivery are shared between the website and the Flutter app.
/// Set SCOPEGUARD_API_URL to point somewhere other than the local dev server.
class SgApi {
  static final String base = (Platform.environment['SCOPEGUARD_API_URL'] ?? 'http://localhost:4000').replaceAll(RegExp(r'/$'), '');
  static final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  static Future<dynamic> call(
    String method,
    String path, {
    String? token,
    Object? body,
    Duration timeout = const Duration(seconds: 150),
  }) async {
    HttpClientResponse? res;
    for (var attempt = 0; res == null; attempt++) {
      try {
        final req = await _http.openUrl(method, Uri.parse('$base$path'));
        // A fresh connection per call: Node closes idle keep-alive sockets, and reusing one fails.
        req.persistentConnection = false;
        req.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (token != null && token.isNotEmpty) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode(body));
        }
        res = await req.close().timeout(timeout);
      } on SocketException {
        // The core API restarts briefly when its files change; wait once before giving up.
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
        throw SgException(message: 'ScopeGuard core API is not running at $base. Start it with start-all.ps1.', status: 503);
      } on TimeoutException {
        throw SgException(message: 'ScopeGuard took too long to answer. Try again.', status: 504);
      } on HttpException {
        if (attempt >= 1) throw SgException(message: 'Lost the connection to ScopeGuard. Try again.', status: 502);
      }
    }
    final text = await res.transform(utf8.decoder).join();
    dynamic data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } catch (_) {
      data = {'error': text};
    }
    if (res.statusCode >= 400) {
      final msg = data is Map && data['error'] != null ? '${data['error']}' : 'ScopeGuard error ${res.statusCode}';
      throw SgException(message: msg, status: res.statusCode);
    }
    return data;
  }

  /// Same as [call] but returns the JSON text, for screens that render ScopeGuard's own order shape.
  static Future<String> json(String method, String path, {String? token, Object? body}) async =>
      jsonEncode(await call(method, path, token: token, body: body));

  static Future<SgSession> me(String token) async {
    final d = await call('GET', '/api/auth/me', token: token);
    return sessionFrom(token, d['user']);
  }

  static SgSession sessionFrom(String token, Map u) => SgSession(
        token: token,
        userId: '${u['id']}',
        name: '${u['name']}',
        email: '${u['email']}',
        role: '${u['role']}',
      );
}
