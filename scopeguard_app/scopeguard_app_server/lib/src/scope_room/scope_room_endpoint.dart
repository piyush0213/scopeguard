import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../scopeguard/sg_api.dart';

/// Scope Room — ScopeGuard's Track 1 ("Here, together") experience.
///
/// At a kickoff meeting the client, developers and anyone else in the room join one order from their own
/// phones (4-letter code or QR). Everyone sees the live quote; the client can switch optional items on or
/// off and every phone updates instantly. Each person taps "Agree". When everyone present agrees to the
/// same version, the scope is agreed in person: every phone lights up in a wave, the agreement (who, which
/// version, which fingerprint) is stored, and it is posted into the order's chat on the website.
/// If the quote changes afterwards (on any device or on the website), earlier agreements stop counting.
class ScopeRoomEndpoint extends Endpoint {
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _lifetime = Duration(hours: 6);
  static const _waveLeadIn = Duration(milliseconds: 2500);
  static const _waveStepMs = 220;
  static const _pollEvery = Duration(seconds: 3);
  static const _maxMembers = 30;
  static final _rand = Random.secure();
  static final Map<String, String> _orderCache = {}; // room code -> latest order JSON

  /// Server clock, so every phone fires the lock wave at the same real moment.
  Future<DateTime> now(Session session) async => DateTime.now().toUtc();

  /// Open a room for an order you can see (the client who owns it, or a developer). If the order already
  /// has an open room you are added to that one instead.
  Future<RoomTicket> open(Session session, String sgToken, String orderId) async {
    final me = await SgApi.me(sgToken);
    final order = await _fetchOrder(sgToken, orderId);
    if (order['paid'] == true) throw SgException(message: 'This order is already paid — its scope is locked.', status: 409);

    var room = await ScopeRoom.db.findFirstRow(
      session,
      where: (t) => t.orderId.equals(orderId) & t.status.notEquals('ended') & (t.expiresAt > DateTime.now().toUtc()),
    );
    if (room == null) {
      final now = DateTime.now().toUtc();
      for (var i = 0; i < 8 && room == null; i++) {
        final code = List.generate(4, (_) => _codeChars[_rand.nextInt(_codeChars.length)]).join();
        if (await ScopeRoom.db.findFirstRow(session, where: (t) => t.code.equals(code) & t.status.notEquals('ended')) != null) continue;
        await ScopeRoom.db.deleteWhere(session, where: (t) => t.code.equals(code));
        room = await ScopeRoom.db.insertRow(
          session,
          ScopeRoom(
            code: code,
            orderId: orderId,
            title: '${order['title']}',
            status: 'open',
            round: 1,
            fingerprint: _fingerprint(order),
            createdAt: now,
            expiresAt: now.add(_lifetime),
            hostToken: sgToken,
          ),
        );
      }
      if (room == null) throw SgException(message: 'Could not create a room code, try again', status: 500);
      _orderCache[room.code] = jsonEncode(order);
    }
    final member = await _addMember(session, room, me.name, me.role, sgToken);
    if (room.hostMemberId == null) {
      room.hostMemberId = member.id;
      await ScopeRoom.db.updateRow(session, room);
    }
    await _broadcast(session, room);
    return RoomTicket(code: room.code, memberId: member.id!, token: member.token!);
  }

  /// Join by code. Signed-in ScopeGuard users who can see the order join with their real role
  /// (client / dev); anyone else joins as a guest who can watch and agree.
  Future<RoomTicket> join(Session session, String code, String name, String sgToken) async {
    final room = await _room(session, code);
    final count = await RoomMember.db.count(session, where: (t) => t.roomId.equals(room.id!));
    if (count >= _maxMembers) throw SgException(message: 'This room is full', status: 409);
    var role = 'guest';
    var displayName = _clean(name, 'Name', 24);
    String? token;
    if (sgToken.isNotEmpty) {
      try {
        final me = await SgApi.me(sgToken);
        await _fetchOrder(sgToken, room.orderId); // throws if this account can't see the order
        role = me.role;
        displayName = me.name;
        token = sgToken;
      } on SgException {
        // Not allowed to see the order through ScopeGuard: still welcome in the room as a guest.
      }
    }
    final member = await _addMember(session, room, displayName, role, token);
    await _broadcast(session, room);
    return RoomTicket(code: room.code, memberId: member.id!, token: member.token!);
  }

  /// The client switches an optional item on or off. Every phone (and the website) sees the new total,
  /// and everyone has to agree again.
  Future<void> toggle(Session session, String code, String token, String moduleId, bool included) async {
    final (room, member) = await _auth(session, code, token);
    if (room.status != 'open') throw SgException(message: 'Re-open the room to change the scope', status: 409);
    if (member.role != 'client' || member.sgToken == null) {
      throw SgException(message: 'Only the client can switch items on the bill', status: 403);
    }
    await SgApi.call('PATCH', '/api/orders/${room.orderId}/toggles', token: member.sgToken, body: {
      'modules': [
        {'id': moduleId, 'included': included}
      ]
    });
    await _refresh(session, room, force: true);
  }

  /// "I agree to this scope" (or take it back). Only counts for the current version of the quote.
  Future<void> agree(Session session, String code, String token, bool yes) async {
    final (room, member) = await _auth(session, code, token);
    if (room.status != 'open') return;
    member.agreedRound = yes ? room.round : 0;
    await RoomMember.db.updateRow(session, member, columns: (t) => [t.agreedRound]);
    await _check(session, room);
    await _broadcast(session, room);
  }

  /// Host: open the scope for changes again after an agreement (everyone must agree again).
  Future<void> reopen(Session session, String code, String token) async {
    final (room, member) = await _auth(session, code, token);
    _requireHost(room, member);
    room
      ..status = 'open'
      ..momentAt = null
      ..round = room.round + 1;
    await ScopeRoom.db.updateRow(session, room);
    await _broadcast(session, room);
  }

  /// Host: the meeting is over. The code stops working; the agreement stays on the order.
  Future<void> end(Session session, String code, String token) async {
    final (room, member) = await _auth(session, code, token);
    _requireHost(room, member);
    room.status = 'ended';
    await ScopeRoom.db.updateRow(session, room);
    await _broadcast(session, room);
    _orderCache.remove(room.code);
  }

  Future<void> leave(Session session, String code, String token) async {
    final (room, member) = await _auth(session, code, token, allowEnded: true);
    await RoomMember.db.deleteRow(session, member);
    if (room.hostMemberId == member.id) {
      final next = await RoomMember.db.findFirstRow(session, where: (t) => t.roomId.equals(room.id!), orderBy: (t) => t.seat);
      room.hostMemberId = next?.id;
      await ScopeRoom.db.updateRow(session, room);
    }
    await _check(session, room);
    await _broadcast(session, room);
  }

  /// Live room. Keeps the member "present" while open, and re-reads the order every few seconds so
  /// changes made on the website (e.g. the developer revising a price) show up here too.
  Stream<RoomState> watch(Session session, String code, String token) async* {
    final (room, member) = await _auth(session, code, token, allowEnded: true);
    final updates = session.messages.createStream<RoomState>(_channel(room.code));
    await _connections(session, member.id!, 1);
    final poll = Timer.periodic(_pollEvery, (_) async {
      try {
        final fresh = await ScopeRoom.db.findById(session, room.id!);
        if (fresh != null && fresh.status != 'ended') await _refresh(session, fresh);
      } catch (_) {/* session closing or API hiccup: next tick retries */}
    });
    try {
      await _broadcast(session, room);
      yield await _state(session, room.id!);
      yield* updates;
    } finally {
      poll.cancel();
      await _connections(session, member.id!, -1);
      final fresh = await ScopeRoom.db.findById(session, room.id!);
      if (fresh != null) {
        await _check(session, fresh);
        await _broadcast(session, fresh);
      }
    }
  }

  // ------------------------------------------------------------------ internals

  /// Re-read the order. If the quote changed, earlier agreements stop counting.
  Future<void> _refresh(Session session, ScopeRoom room, {bool force = false}) async {
    if (room.hostToken == null) return;
    final order = await _fetchOrder(room.hostToken!, room.orderId);
    final json = jsonEncode(order);
    final changedJson = _orderCache[room.code] != json;
    _orderCache[room.code] = json;
    final fp = _fingerprint(order);
    if (fp != room.fingerprint) {
      room.fingerprint = fp;
      if (order['paid'] != true) {
        room
          ..status = room.status == 'ended' ? 'ended' : 'open'
          ..momentAt = null
          ..round = room.round + 1;
      }
      await ScopeRoom.db.updateRow(session, room);
    }
    if (changedJson || force || fp != room.fingerprint) await _broadcast(session, room);
  }

  /// Everyone currently here (2+ people) agreed to this version -> agreed in person.
  Future<void> _check(Session session, ScopeRoom room) async {
    if (room.status != 'open') return;
    final here = (await RoomMember.db.find(session, where: (t) => t.roomId.equals(room.id!), orderBy: (t) => t.seat))
        .where((m) => m.connections > 0)
        .toList();
    if (here.length < 2 || here.any((m) => m.agreedRound != room.round)) return;

    final order = jsonDecode(_orderCache[room.code] ?? '{}') as Map<String, dynamic>;
    final quote = order['quote'] as Map<String, dynamic>?;
    final total = _total(quote);
    room
      ..status = 'agreed'
      ..momentAt = DateTime.now().toUtc().add(_waveLeadIn);
    await ScopeRoom.db.updateRow(session, room);
    final signers = here.map((m) => '${m.name} (${m.role})').toList();
    await ScopeAgreement.db.insertRow(
      session,
      ScopeAgreement(
        roomId: room.id!,
        orderId: room.orderId,
        quoteVersion: (quote?['version'] as num?)?.toInt() ?? 1,
        totalCents: total,
        fingerprint: room.fingerprint ?? '',
        signers: signers,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    // Leave a permanent note on the order, visible on the website too.
    if (room.hostToken != null) {
      try {
        await SgApi.call('POST', '/api/orders/${room.orderId}/messages', token: room.hostToken, body: {
          'content': '🤝 Scope agreed in person in Scope Room ${room.code} by ${signers.join(', ')} — '
              'quote v${quote?['version'] ?? 1}, ${_usd(total)}, fingerprint ${room.fingerprint?.substring(0, 12)}…',
        });
      } catch (_) {/* the agreement is stored even if the chat note fails */}
    }
  }

  Future<RoomState> _state(Session session, int roomId) async {
    final room = (await ScopeRoom.db.findById(session, roomId))!;
    final members = await RoomMember.db.find(session, where: (t) => t.roomId.equals(roomId), orderBy: (t) => t.seat);
    var orderJson = _orderCache[room.code];
    if (orderJson == null && room.hostToken != null) {
      try {
        orderJson = jsonEncode(await _fetchOrder(room.hostToken!, room.orderId));
        _orderCache[room.code] = orderJson;
      } catch (_) {}
    }
    LockMoment? moment;
    ScopeAgreement? agreement;
    if (room.status == 'agreed') {
      agreement = await ScopeAgreement.db.findFirstRow(
        session,
        where: (t) => t.roomId.equals(roomId),
        orderByList: (t) => [t.createdAt.desc()],
      );
      if (room.momentAt != null) {
        moment = LockMoment(
          startAt: room.momentAt!,
          stepMs: _waveStepMs,
          order: members.where((m) => m.connections > 0).map((m) => m.id!).toList(),
        );
      }
    }
    return RoomState(
      room: room,
      members: members,
      orderJson: orderJson ?? '{}',
      moment: moment,
      agreement: agreement,
      serverTime: DateTime.now().toUtc(),
    );
  }

  Future<void> _broadcast(Session session, ScopeRoom room) async =>
      session.messages.postMessage(_channel(room.code), await _state(session, room.id!));

  Future<Map<String, dynamic>> _fetchOrder(String sgToken, String orderId) async {
    final d = await SgApi.call('GET', '/api/orders/$orderId', token: sgToken);
    return (d['order'] as Map).cast<String, dynamic>();
  }

  static List<Map> _lockedItems(Map<String, dynamic>? quote) => [
        for (final m in (quote?['modules'] as List? ?? const []))
          if (m['included'] == true || m['optional'] != true) m as Map
      ];

  static int _total(Map<String, dynamic>? quote) =>
      _lockedItems(quote).fold(0, (s, m) => s + ((m['price_cents'] as num?)?.toInt() ?? 0));

  /// What people agree to: quote version + every included item and its price.
  static String _fingerprint(Map<String, dynamic> order) {
    final quote = order['quote'] as Map<String, dynamic>?;
    final canonical = jsonEncode({
      'version': quote?['version'],
      'items': [
        for (final m in _lockedItems(quote)) [m['id'], m['name'], m['price_cents']]
      ]..sort((a, b) => '${a[0]}'.compareTo('${b[0]}')),
    });
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  Future<void> _connections(Session session, int memberId, int delta) async {
    final m = await RoomMember.db.findById(session, memberId);
    if (m == null) return;
    m.connections = max(0, m.connections + delta);
    await RoomMember.db.updateRow(session, m, columns: (t) => [t.connections]);
  }

  Future<RoomMember> _addMember(Session session, ScopeRoom room, String name, String role, String? sgToken) async {
    // The same signed-in person coming back (reopening the room, reloading the page) keeps their seat.
    if (sgToken != null) {
      final existing = await RoomMember.db.findFirstRow(session, where: (t) => t.roomId.equals(room.id!) & t.sgToken.equals(sgToken));
      if (existing != null) return existing;
    }
    final last = await RoomMember.db.findFirstRow(
      session,
      where: (t) => t.roomId.equals(room.id!),
      orderByList: (t) => [t.seat.desc()],
    );
    final seat = (last?.seat ?? -1) + 1;
    return RoomMember.db.insertRow(
      session,
      RoomMember(
        roomId: room.id!,
        name: name,
        role: role,
        color: seat % 8,
        seat: seat,
        connections: 0,
        agreedRound: 0,
        joinedAt: DateTime.now().toUtc(),
        token: List.generate(32, (_) => _rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join(),
        sgToken: sgToken,
      ),
    );
  }

  Future<ScopeRoom> _room(Session session, String code, {bool allowEnded = false}) async {
    final room = await ScopeRoom.db.findFirstRow(session, where: (t) => t.code.equals(code.trim().toUpperCase()));
    if (room == null) throw SgException(message: 'No Scope Room with code ${code.toUpperCase()}', status: 404);
    if (!allowEnded && (room.status == 'ended' || room.expiresAt.isBefore(DateTime.now().toUtc()))) {
      throw SgException(message: 'This Scope Room has ended', status: 409);
    }
    return room;
  }

  Future<(ScopeRoom, RoomMember)> _auth(Session session, String code, String token, {bool allowEnded = false}) async {
    final room = await _room(session, code, allowEnded: allowEnded);
    final member = await RoomMember.db.findFirstRow(session, where: (t) => t.roomId.equals(room.id!) & t.token.equals(token));
    if (member == null) throw SgException(message: 'You are not in this room', status: 403);
    return (room, member);
  }

  void _requireHost(ScopeRoom room, RoomMember member) {
    if (room.hostMemberId != member.id) throw SgException(message: 'Only the host can do that', status: 403);
  }

  String _clean(String s, String field, int maxLen) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) throw SgException(message: '$field is required', status: 400);
    return t.length > maxLen ? t.substring(0, maxLen) : t;
  }

  String _channel(String code) => 'scope_room_$code';

  static String _usd(int cents) {
    final whole = (cents ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '\$$whole.${(cents % 100).toString().padLeft(2, '0')}';
  }
}
