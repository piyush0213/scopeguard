import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:scopeguard_app_client/scopeguard_app_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// Server address, in this order: --dart-define=SERVER_URL=..., then (web) the computer that served the
// page, then assets/config.json, then http://localhost:8080/ (10.0.2.2 on the Android emulator).
// For a real phone running the native app, build with --dart-define=SERVER_URL=http://<laptop-ip>:8080/
final serverUrl = getServerUrl();

late final Client client;

Future<String> _resolveServerUrl() async {
  const fromDefine = String.fromEnvironment('SERVER_URL');
  final base = Uri.base;
  if (kIsWeb && fromDefine.isEmpty && base.scheme.startsWith('http') && base.host != 'localhost' && base.host != '127.0.0.1') {
    // Opened straight from the laptop's web server over Wi-Fi (http://<laptop-ip>:8082): the API is on :8080.
    if (base.port == 8082) return 'http://${base.host}:8080/';
    // Opened through the mobile gateway / public tunnel: the API is on the same address as the page.
    return '${base.origin}/';
  }
  return serverUrl;
}

Future<void> initializeClient() async {
  // AI scoping can take a minute, so allow long calls.
  client = Client(await _resolveServerUrl(), connectionTimeout: const Duration(seconds: 180))
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
