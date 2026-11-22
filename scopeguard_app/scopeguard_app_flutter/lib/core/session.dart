import 'package:flutter/foundation.dart';
import 'package:scopeguard_app_client/scopeguard_app_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../client.dart';

/// The signed-in ScopeGuard user (same account as the website). Null when signed out.
final currentUser = ValueNotifier<SgSession?>(null);

String get token => currentUser.value?.token ?? '';
bool get isDev => currentUser.value?.role == 'dev';

const _key = 'sg_token';

Future<void> restoreSession() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_key);
  if (saved == null || saved.isEmpty) return;
  try {
    currentUser.value = await client.account.me(saved);
  } on SgException catch (e) {
    if (e.status == 401) await prefs.remove(_key);
  } catch (_) {
    // Server not reachable yet: stay signed out; the login screen explains.
  }
}

Future<void> signIn(SgSession s) async {
  (await SharedPreferences.getInstance()).setString(_key, s.token);
  currentUser.value = s;
}

Future<void> signOut() async {
  (await SharedPreferences.getInstance()).remove(_key);
  currentUser.value = null;
}
