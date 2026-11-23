import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:scopeguard_app/features/orders/chat_draft_submission.dart';

void main() {
  late TextEditingController controller;
  late ChatDraftSubmission submission;

  setUp(() {
    controller = TextEditingController();
    submission = ChatDraftSubmission();
  });

  tearDown(() => controller.dispose());

  test('empty messages are ignored', () async {
    controller.text = '   ';
    var sendCount = 0;

    final sent = await submission.submit(controller, (_) async {
      sendCount++;
      return true;
    });

    expect(sent, isFalse);
    expect(sendCount, 0);
    expect(controller.text, '   ');
  });

  test('successful submission clears the draft', () async {
    controller.text = '  Please add dark mode  ';
    String? sentMessage;

    final sent = await submission.submit(controller, (message) async {
      sentMessage = message;
      return true;
    });

    expect(sent, isTrue);
    expect(sentMessage, 'Please add dark mode');
    expect(controller.text, isEmpty);
  });

  test('failed submission retains the draft', () async {
    controller.text = 'Please add dark mode';

    final sent = await submission.submit(controller, (_) async => false);

    expect(sent, isFalse);
    expect(controller.text, 'Please add dark mode');
  });

  test('duplicate submissions are ignored while a send is pending', () async {
    controller.text = 'Please add dark mode';
    final sendResult = Completer<bool>();
    var sendCount = 0;

    final firstSend = submission.submit(controller, (_) {
      sendCount++;
      return sendResult.future;
    });
    final duplicateSend = await submission.submit(controller, (_) async {
      sendCount++;
      return true;
    });

    expect(submission.isSending, isTrue);
    expect(duplicateSend, isFalse);
    expect(sendCount, 1);

    sendResult.complete(true);
    expect(await firstSend, isTrue);
    expect(submission.isSending, isFalse);
    expect(controller.text, isEmpty);
  });
}
