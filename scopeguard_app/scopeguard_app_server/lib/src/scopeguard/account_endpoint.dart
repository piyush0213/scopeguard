import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'sg_api.dart';

/// Sign in with a ScopeGuard account. The token is the same JWT the website uses.
class AccountEndpoint extends Endpoint {
  Future<SgSession> login(Session session, String email, String password) async {
    final d = await SgApi.call('POST', '/api/auth/login', body: {'email': email.trim(), 'password': password});
    return SgApi.sessionFrom('${d['token']}', d['user']);
  }

  Future<SgSession> register(Session session, String name, String email, String password, String role) async {
    if (role != 'client' && role != 'dev') throw SgException(message: 'Pick client or developer', status: 400);
    final d = await SgApi.call('POST', '/api/auth/register',
        body: {'name': name.trim(), 'email': email.trim(), 'password': password, 'role': role});
    return SgApi.sessionFrom('${d['token']}', d['user']);
  }

  /// Restores a saved session; throws 401 when the token expired.
  Future<SgSession> me(Session session, String token) => SgApi.me(token);
}
