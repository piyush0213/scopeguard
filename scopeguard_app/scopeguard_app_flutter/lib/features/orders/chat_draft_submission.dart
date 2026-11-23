import 'package:flutter/widgets.dart';

/// Submits the current chat draft once, clearing it only when the send succeeds.
class ChatDraftSubmission {
  bool _isSending = false;

  bool get isSending => _isSending;

  Future<bool> submit(
    TextEditingController controller,
    Future<bool> Function(String message) send,
  ) async {
    if (_isSending) return false;

    final draft = controller.text;
    final message = draft.trim();
    if (message.isEmpty) return false;

    _isSending = true;
    try {
      final sent = await send(message);
      if (sent && controller.text == draft) controller.clear();
      return sent;
    } finally {
      _isSending = false;
    }
  }
}
