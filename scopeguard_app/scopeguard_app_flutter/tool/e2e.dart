// End-to-end check of the Flutter version's backend (Serverpod) against the running ScopeGuard core:
// sign-in, AI scoping, dev approval, then a Scope Room with a client, a developer and a guest.
// Run (start-all.ps1 must be running):  dart run tool/e2e.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:scopeguard_app_client/scopeguard_app_client.dart';

const url = 'http://localhost:8080/';
var failures = 0;
void check(bool ok, String label) {
  stdout.writeln('${ok ? 'PASS' : 'FAIL'}  $label');
  if (!ok) failures++;
}

class Phone {
  Phone(this.label) : c = Client(url, connectionTimeout: const Duration(seconds: 180));
  final String label;
  final Client c;
  late RoomTicket t;
  RoomState? last;
  StreamSubscription<RoomState>? sub;
  void watch() => sub = c.scopeRoom.watch(t.code, t.token).listen((s) => last = s);
  Future<RoomState> until(bool Function(RoomState) ok, String what, {int secs = 15}) async {
    final end = DateTime.now().add(Duration(seconds: secs));
    while (DateTime.now().isBefore(end)) {
      if (last != null && ok(last!)) return last!;
      await Future.delayed(const Duration(milliseconds: 150));
    }
    throw TimeoutException('$label never saw: $what');
  }

  Map<String, dynamic> get order => jsonDecode(last!.orderJson) as Map<String, dynamic>;
}

Future<void> main() async {
  final clientPhone = Phone('client'), devPhone = Phone('dev'), guestPhone = Phone('guest');
  String? orderId;
  try {
    // 1. Same accounts as the website.
    final asha = await clientPhone.c.account.login('client@demo.dev', 'demo1234');
    final ravi = await devPhone.c.account.login('dev@demo.dev', 'demo1234');
    check(asha.role == 'client' && ravi.role == 'dev', 'client and developer sign in with their website accounts');
    try {
      await guestPhone.c.account.login('client@demo.dev', 'wrong');
      check(false, 'wrong password rejected');
    } on SgException catch (e) {
      check(e.status == 401 || e.status == 400, 'wrong password rejected (${e.message})');
    }

    // 2. Menu + AI scoping through Serverpod.
    final menu = jsonDecode(await clientPhone.c.shop.menu(asha.token))['items'] as List;
    check(menu.length >= 4, 'menu loads (${menu.length} items)');
    stdout.writeln('      asking the AI for questions…');
    final q = jsonDecode(await clientPhone.c.shop.startScoping(asha.token,
        'I run a dental clinic with 3 dentists and want patients to book online.',
        'A chatbot that answers patient FAQs and books appointments.', ['landing-page']));
    orderId = q['orderId'] as String;
    final questions = q['questions'] as List;
    check(questions.isNotEmpty, 'AI asked ${questions.length} questions for $orderId');
    stdout.writeln('      AI is drafting the quote…');
    final answers = [for (final x in questions) ((x['suggestions'] as List?)?.isNotEmpty ?? false) ? '${x['suggestions'][0]}' : 'Yes'];
    final drafted = jsonDecode(await clientPhone.c.shop.answerScoping(asha.token, orderId, answers))['order'];
    check(drafted['status'] == 'ai_draft', 'AI drafted a quote (${(drafted['quote']['modules'] as List).length} items)');

    // 3. Developer approves from the app's kitchen.
    await devPhone.c.kitchen.approveQuote(ravi.token, '${drafted['quote']['id']}');
    final queue = jsonDecode(await devPhone.c.kitchen.queue(ravi.token))['orders'] as List;
    check(queue.any((o) => o['id'] == orderId && o['status'] == 'negotiating'), 'developer approved the quote; it is now negotiating');

    // 4. Scope Room: client opens, developer joins signed in, a guest joins with a name.
    clientPhone.t = await clientPhone.c.scopeRoom.open(asha.token, orderId);
    devPhone.t = await devPhone.c.scopeRoom.join(clientPhone.t.code, 'ignored', ravi.token);
    guestPhone.t = await guestPhone.c.scopeRoom.join(clientPhone.t.code.toLowerCase(), 'Meera', '');
    for (final p in [clientPhone, devPhone, guestPhone]) {
      p.watch();
    }
    final s0 = await guestPhone.until((s) => s.members.where((m) => m.connections > 0).length == 3, '3 people present');
    check(true, 'room ${clientPhone.t.code}: 3 phones live');
    final roles = {for (final m in s0.members) m.name: m.role};
    check(roles['Asha (Clinic Owner)'] == 'client' && roles['Ravi (Agency Dev)'] == 'dev' && roles['Meera'] == 'guest',
        'roles come from ScopeGuard accounts; guest stays a guest ($roles)');
    check(guestPhone.order['id'] == orderId && guestPhone.order['quote'] != null, 'even the guest sees the live quote');
    check(!s0.members.first.toJson().containsKey('token') && !s0.members.first.toJson().containsKey('sgToken'),
        'member secrets and ScopeGuard tokens never reach phones');

    // 5. Permissions.
    final optional = (clientPhone.order['quote']['modules'] as List).where((m) => m['optional'] == true).toList();
    for (final p in [devPhone, guestPhone]) {
      try {
        await p.c.scopeRoom.toggle(p.t.code, p.t.token, 'x', false);
        check(false, '${p.label} cannot change the bill');
      } on SgException catch (e) {
        check(e.status == 403, '${p.label} cannot change the bill');
      }
    }

    // 6. Two agree; the client changes an item -> agreements reset; everyone agrees -> locked in person.
    await devPhone.c.scopeRoom.agree(devPhone.t.code, devPhone.t.token, true);
    await guestPhone.c.scopeRoom.agree(guestPhone.t.code, guestPhone.t.token, true);
    await Future.delayed(const Duration(milliseconds: 500));
    check(clientPhone.last!.room.status == 'open', 'not agreed while the client has not agreed');
    if (optional.isNotEmpty) {
      final roundBefore = clientPhone.last!.room.round;
      final totalBefore = clientPhone.order['totalCents'];
      await clientPhone.c.scopeRoom.toggle(clientPhone.t.code, clientPhone.t.token, '${optional.first['id']}', false);
      final s = await devPhone.until((s) => s.room.round > roundBefore, 'round reset after a change');
      check(s.members.every((m) => m.agreedRound != s.room.round), 'switching "${optional.first['name']}" off reset everyone\'s agreement');
      check(devPhone.order['totalCents'] != totalBefore, 'new total reached the developer\'s phone (${devPhone.order['totalCents']})');
    } else {
      stdout.writeln('      (AI quote had no optional items; skipped the toggle check)');
    }
    for (final p in [clientPhone, devPhone, guestPhone]) {
      await p.c.scopeRoom.agree(p.t.code, p.t.token, true);
    }
    final locked = await Future.wait([for (final p in [clientPhone, devPhone, guestPhone]) p.until((s) => s.moment != null, 'lock moment')]);
    check(locked.every((s) => s.room.status == 'agreed'), 'everyone agreed: scope agreed in person');
    check(locked.every((s) => s.moment!.startAt == locked.first.moment!.startAt), 'all 3 phones got the same lock-wave start time');
    check(locked.first.agreement?.signers.length == 3, 'agreement stored with 3 signers: ${locked.first.agreement?.signers}');

    // 7. The website sees it: chat note on the order.
    final onWeb = jsonDecode(await clientPhone.c.orders.get(asha.token, orderId));
    check((onWeb['messages'] as List).any((m) => '${m['content']}'.contains('Scope agreed in person')),
        'the agreement appears in the order chat on the website');

    // 8. A change made outside the room (developer reprices, like on the website) re-opens it.
    final mod = (onWeb['order']['quote']['modules'] as List).firstWhere((m) => m['menu'] != true, orElse: () => onWeb['order']['quote']['modules'][0]);
    await devPhone.c.kitchen.reprice(ravi.token, '${onWeb['order']['quote']['id']}', '${mod['id']}', (mod['price_cents'] as int) + 5000, 'Added hosting');
    final reopened = await clientPhone.until((s) => s.room.status == 'open', 'room re-opened after price change', secs: 12);
    check(reopened.room.round > locked.first.room.round, 'a price change on the website re-opens the room: everyone must agree again');

    // 9. Live order stream (used by the app's order screen).
    final first = await clientPhone.c.orders.watch(asha.token, orderId).first.timeout(const Duration(seconds: 10));
    check(jsonDecode(first)['order']['id'] == orderId, 'live order stream works');

    // 10. Host ends the room.
    await clientPhone.c.scopeRoom.end(clientPhone.t.code, clientPhone.t.token);
    await guestPhone.until((s) => s.room.status == 'ended', 'ended');
    try {
      await guestPhone.c.scopeRoom.join(clientPhone.t.code, 'Late', '');
      check(false, 'ended room cannot be joined');
    } on SgException {
      check(true, 'host ended the room; the code no longer works');
    }
  } catch (e, st) {
    check(false, 'unexpected: $e\n$st');
  } finally {
    for (final p in [clientPhone, devPhone, guestPhone]) {
      await p.sub?.cancel();
      p.c.close();
    }
  }
  stdout.writeln(failures == 0 ? '\nALL PASSED  (test order: $orderId)' : '\n$failures FAILED  (test order: $orderId)');
  exit(failures == 0 ? 0 : 1);
}
