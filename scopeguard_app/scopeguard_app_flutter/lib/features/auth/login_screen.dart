import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../room/join_room_screen.dart';

/// Sign in with the same ScopeGuard account as the website, or join a Scope Room as a guest.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  String _role = 'client';
  bool _busy = false;
  String? _error;

  Future<void> _submit({String? email, String? password}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = _register && email == null
          ? await client.account.register(_name.text, _email.text, _password.text, _role)
          : await client.account.login(email ?? _email.text, password ?? _password.text);
      await signIn(s);
    } catch (e) {
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Narrow(
          max: 460,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 40, 24, 32), children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: brand.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shield_outlined, color: brand, size: 20),
              ),
              const SizedBox(width: 10),
              Text('ScopeGuard', style: display(26)),
            ]),
            const SizedBox(height: 36),
            Text('Pay for proof,', style: display(54)),
            Text('not promises.', style: display(54, color: leaf, style: FontStyle.italic)),
            const SizedBox(height: 14),
            const Text(
              'Order software off a menu, agree the scope together in one room, and pay each item only when the code proves it.',
              style: TextStyle(color: muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            Eyebrow('1-tap demo seats'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Seat(title: 'Client', sub: 'Order · agree · verify', onTap: _busy ? null : () => _submit(email: 'client@demo.dev', password: 'demo1234'))),
              const SizedBox(width: 12),
              Expanded(child: _Seat(title: 'Developer', sub: 'Quote · build · prove', onTap: _busy ? null : () => _submit(email: 'dev@demo.dev', password: 'demo1234'))),
            ]),
            const SizedBox(height: 28),
            Eyebrow(_register ? 'Create an account' : 'Or sign in'),
            const SizedBox(height: 10),
            if (_register) ...[
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'Name')),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'client', label: Text('I need software')), ButtonSegment(value: 'dev', label: Text('I build software'))],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 10),
            ],
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(hintText: 'Password'), onSubmitted: (_) => _submit()),
            if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: brand))],
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'One moment…' : _register ? 'Create account' : 'Sign in')),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(_register ? 'I already have an account' : 'New here? Create an account', style: const TextStyle(color: muted)),
            ),
            const SizedBox(height: 16),
            Panel(
              accent: cyan,
              child: Row(children: [
                const Icon(Icons.groups_2_outlined, color: cyan),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('In a kickoff meeting? Join the Scope Room with the 4-letter code — no account needed.',
                      style: TextStyle(color: muted, height: 1.4)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinRoomScreen())),
                  child: const Text('Join', style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.title, required this.sub, required this.onTap});
  final String title;
  final String sub;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Panel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(title, style: display(26)), const Spacer(), const Icon(Icons.arrow_forward, size: 16, color: faint)]),
            const SizedBox(height: 4),
            Text(sub, style: mono(10, color: brand)),
          ]),
        ),
      );
}
