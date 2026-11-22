import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import 'room_screen.dart';

/// Join a Scope Room with its 4-letter code. Signed-in users join with their ScopeGuard role;
/// anyone else (e.g. the client's co-founder in the meeting) joins as a guest with just a name.
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key, this.initialCode, this.embedded = false, this.standalone = false});
  final String? initialCode;
  final bool embedded; // shown as a tab inside the home screen
  final bool standalone; // opened from a QR link
  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late final _code = TextEditingController(text: widget.initialCode?.toUpperCase() ?? '');
  late final _name = TextEditingController(text: currentUser.value?.name ?? '');
  bool _busy = false;
  bool _asGuest = false;
  String? _error;

  String get _sgToken => _asGuest ? '' : token;

  Future<void> _join() async {
    if (_code.text.trim().length != 4) return setState(() => _error = 'Room codes are 4 characters');
    if (_sgToken.isEmpty && _name.text.trim().isEmpty) return setState(() => _error = 'Tell the room your name');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final t = await client.scopeRoom.join(_code.text.trim().toUpperCase(), _name.text.trim().isEmpty ? 'Guest' : _name.text.trim(), _sgToken);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(ticket: t)));
    } catch (e) {
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Narrow(
      max: 460,
      child: ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), children: [
        Text('Scope', style: display(48)),
        Text('Room', style: display(48, color: cyan, style: FontStyle.italic)),
        const SizedBox(height: 12),
        const Text(
          'Everyone at the kickoff meeting joins one order from their own phone, watches the bill change live, '
          'and agrees to the scope together. When everyone agrees, every phone lights up and the scope is locked in.',
          style: TextStyle(color: muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          maxLength: 4,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, letterSpacing: 14, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(hintText: 'CODE', counterText: ''),
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 10),
        if (token.isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: !_asGuest,
            onChanged: (v) => setState(() {
              _asGuest = !v;
              if (_asGuest) _name.clear();
            }),
            title: Text('Join as ${currentUser.value!.name} (${currentUser.value!.role})'),
            subtitle: const Text('Turn off to join as a guest with another name', style: TextStyle(color: muted, fontSize: 12)),
          ),
        if (_sgToken.isEmpty)
          TextField(controller: _name, decoration: const InputDecoration(hintText: 'Your name'), onSubmitted: (_) => _join()),
        if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: brand))],
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cyan, foregroundColor: canvas),
          onPressed: _busy ? null : _join,
          child: Text(_busy ? 'Joining…' : 'Join room'),
        ),
        const SizedBox(height: 16),
        Text(
          isDev || token.isNotEmpty
              ? 'To start a room, open an unpaid order and tap “Open” on the Scope Room card.'
              : 'No account needed to join.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: faint, fontSize: 12),
        ),
      ]),
    );
    if (widget.embedded) return body;
    return Scaffold(appBar: AppBar(), body: SafeArea(child: body));
  }
}
