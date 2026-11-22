import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'client.dart';
import 'core/payments.dart';
import 'core/session.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/room/join_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  await restoreSession();
  await loadPendingPayments();
  readStripeReturn();
  runApp(const ScopeGuardApp());
}

class ScopeGuardApp extends StatelessWidget {
  const ScopeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A Scope Room QR code opens https://<host>/?room=ABCD straight into the join screen.
    final roomCode = Uri.base.queryParameters['room'];
    return MaterialApp(
      title: 'ScopeGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ValueListenableBuilder(
        valueListenable: currentUser,
        builder: (context, user, _) {
          if (roomCode != null && roomCode.length == 4) return JoinRoomScreen(initialCode: roomCode, standalone: true);
          return user == null ? const LoginScreen() : HomeShell(key: ValueKey(user.userId));
        },
      ),
    );
  }
}
