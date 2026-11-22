/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Scope Room (Track 1 "Here, together"): everyone at the kickoff meeting joins one ScopeGuard order from
/// their own phone, watches the quote change live and agrees to the scope together. Temporary by design.
abstract class ScopeRoom
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ScopeRoom._({
    this.id,
    required this.code,
    required this.orderId,
    required this.title,
    required this.status,
    this.hostMemberId,
    required this.round,
    this.fingerprint,
    this.momentAt,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ScopeRoom({
    int? id,
    required String code,
    required String orderId,
    required String title,
    required String status,
    int? hostMemberId,
    required int round,
    String? fingerprint,
    DateTime? momentAt,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) = _ScopeRoomImpl;

  factory ScopeRoom.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScopeRoom(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      orderId: jsonSerialization['orderId'] as String,
      title: jsonSerialization['title'] as String,
      status: jsonSerialization['status'] as String,
      hostMemberId: jsonSerialization['hostMemberId'] as int?,
      round: jsonSerialization['round'] as int,
      fingerprint: jsonSerialization['fingerprint'] as String?,
      momentAt: jsonSerialization['momentAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['momentAt']),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 4-letter join code shown on screen and in the QR.
  String code;

  /// The ScopeGuard order this room negotiates, e.g. CD-1052.
  String orderId;

  String title;

  /// open | agreed | ended
  String status;

  int? hostMemberId;

  /// Bumped whenever the quote changes: earlier "agree" taps no longer count.
  int round;

  /// sha256 of the quote version + included items + prices that people are agreeing to.
  String? fingerprint;

  /// When the synchronized lock wave starts on every phone (server clock).
  DateTime? momentAt;

  DateTime createdAt;

  DateTime expiresAt;

  /// Returns a shallow copy of this [ScopeRoom]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ScopeRoom copyWith({
    int? id,
    String? code,
    String? orderId,
    String? title,
    String? status,
    int? hostMemberId,
    int? round,
    String? fingerprint,
    DateTime? momentAt = const _isc.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScopeRoom',
      if (id != null) 'id': id,
      'code': code,
      'orderId': orderId,
      'title': title,
      'status': status,
      if (hostMemberId != null) 'hostMemberId': hostMemberId,
      'round': round,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (momentAt != null) 'momentAt': momentAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ScopeRoom',
      if (id != null) 'id': id,
      'code': code,
      'orderId': orderId,
      'title': title,
      'status': status,
      if (hostMemberId != null) 'hostMemberId': hostMemberId,
      'round': round,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (momentAt != null) 'momentAt': momentAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScopeRoomImpl extends ScopeRoom {
  _ScopeRoomImpl({
    int? id,
    required String code,
    required String orderId,
    required String title,
    required String status,
    int? hostMemberId,
    required int round,
    String? fingerprint,
    DateTime? momentAt,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         code: code,
         orderId: orderId,
         title: title,
         status: status,
         hostMemberId: hostMemberId,
         round: round,
         fingerprint: fingerprint,
         momentAt: momentAt,
         createdAt: createdAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ScopeRoom]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ScopeRoom copyWith({
    Object? id = _Undefined,
    String? code,
    String? orderId,
    String? title,
    String? status,
    Object? hostMemberId = _Undefined,
    int? round,
    Object? fingerprint = _Undefined,
    DateTime? momentAt = const _isc.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ScopeRoom(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      status: status ?? this.status,
      hostMemberId: hostMemberId is int? ? hostMemberId : this.hostMemberId,
      round: round ?? this.round,
      fingerprint: fingerprint is String? ? fingerprint : this.fingerprint,
      momentAt: momentAt is _isc.UndefinedSentinel ? this.momentAt : momentAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
