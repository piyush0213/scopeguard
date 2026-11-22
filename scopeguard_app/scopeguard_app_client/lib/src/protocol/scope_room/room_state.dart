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
import 'package:scopeguard_app_client/src/protocol/protocol.dart' as _imf57qlp;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../scope_room/lock_moment.dart' as _ikxo3dvq;
import '../scope_room/room_member.dart' as _is1btp4e;
import '../scope_room/scope_agreement.dart' as _ix4kihyr;
import '../scope_room/scope_room.dart' as _ibchvmtm;

/// Everything a phone in the room needs, pushed live after every change.
abstract class RoomState
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RoomState._({
    required this.room,
    required this.members,
    required this.orderJson,
    this.moment,
    this.agreement,
    required this.serverTime,
  });

  factory RoomState({
    required _ibchvmtm.ScopeRoom room,
    required List<_is1btp4e.RoomMember> members,
    required String orderJson,
    _ikxo3dvq.LockMoment? moment,
    _ix4kihyr.ScopeAgreement? agreement,
    required DateTime serverTime,
  }) = _RoomStateImpl;

  factory RoomState.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomState(
      room: _imf57qlp.Protocol().deserialize<_ibchvmtm.ScopeRoom>(
        jsonSerialization['room'],
      ),
      members: _imf57qlp.Protocol().deserialize<List<_is1btp4e.RoomMember>>(
        jsonSerialization['members'],
      ),
      orderJson: jsonSerialization['orderJson'] as String,
      moment: jsonSerialization['moment'] == null
          ? null
          : _imf57qlp.Protocol().deserialize<_ikxo3dvq.LockMoment>(
              jsonSerialization['moment'],
            ),
      agreement: jsonSerialization['agreement'] == null
          ? null
          : _imf57qlp.Protocol().deserialize<_ix4kihyr.ScopeAgreement>(
              jsonSerialization['agreement'],
            ),
      serverTime: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTime'],
      ),
    );
  }

  _ibchvmtm.ScopeRoom room;

  List<_is1btp4e.RoomMember> members;

  /// The ScopeGuard order (JSON, same shape the website uses): live quote, items, total, status.
  String orderJson;

  _ikxo3dvq.LockMoment? moment;

  /// Set once everyone agreed.
  _ix4kihyr.ScopeAgreement? agreement;

  DateTime serverTime;

  /// Returns a shallow copy of this [RoomState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RoomState copyWith({
    _ibchvmtm.ScopeRoom? room,
    List<_is1btp4e.RoomMember>? members,
    String? orderJson,
    _ikxo3dvq.LockMoment? moment = const _UndefinedRoomState$moment(),
    _ix4kihyr.ScopeAgreement? agreement = const _UndefinedRoomState$agreement(),
    DateTime? serverTime,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomState',
      'room': room.toJson(),
      'members': members.toJson(valueToJson: (v) => v.toJson()),
      'orderJson': orderJson,
      if (moment != null) 'moment': moment?.toJson(),
      if (agreement != null) 'agreement': agreement?.toJson(),
      'serverTime': serverTime.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RoomState',
      'room': room.toJsonForProtocol(),
      'members': members.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'orderJson': orderJson,
      if (moment != null) 'moment': moment?.toJsonForProtocol(),
      if (agreement != null) 'agreement': agreement?.toJsonForProtocol(),
      'serverTime': serverTime.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _UndefinedRoomState$moment extends _isc.UndefinedSentinel
    implements _ikxo3dvq.LockMoment {
  const _UndefinedRoomState$moment();
}

class _UndefinedRoomState$agreement extends _isc.UndefinedSentinel
    implements _ix4kihyr.ScopeAgreement {
  const _UndefinedRoomState$agreement();
}

class _RoomStateImpl extends RoomState {
  _RoomStateImpl({
    required _ibchvmtm.ScopeRoom room,
    required List<_is1btp4e.RoomMember> members,
    required String orderJson,
    _ikxo3dvq.LockMoment? moment,
    _ix4kihyr.ScopeAgreement? agreement,
    required DateTime serverTime,
  }) : super._(
         room: room,
         members: members,
         orderJson: orderJson,
         moment: moment,
         agreement: agreement,
         serverTime: serverTime,
       );

  /// Returns a shallow copy of this [RoomState]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RoomState copyWith({
    _ibchvmtm.ScopeRoom? room,
    List<_is1btp4e.RoomMember>? members,
    String? orderJson,
    _ikxo3dvq.LockMoment? moment = const _UndefinedRoomState$moment(),
    _ix4kihyr.ScopeAgreement? agreement = const _UndefinedRoomState$agreement(),
    DateTime? serverTime,
  }) {
    return RoomState(
      room: room ?? this.room.copyWith(),
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
      orderJson: orderJson ?? this.orderJson,
      moment: moment is _isc.UndefinedSentinel
          ? this.moment?.copyWith()
          : moment,
      agreement: agreement is _isc.UndefinedSentinel
          ? this.agreement?.copyWith()
          : agreement,
      serverTime: serverTime ?? this.serverTime,
    );
  }
}
