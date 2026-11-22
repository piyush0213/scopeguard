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

/// Someone in the room. Signed-in ScopeGuard users get their real role; anyone else joins as a guest
/// (e.g. the client's co-founder) with just a name.
abstract class RoomMember
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RoomMember._({
    this.id,
    required this.roomId,
    required this.name,
    required this.role,
    required this.color,
    required this.seat,
    required this.connections,
    required this.agreedRound,
    required this.joinedAt,
  });

  factory RoomMember({
    int? id,
    required int roomId,
    required String name,
    required String role,
    required int color,
    required int seat,
    required int connections,
    required int agreedRound,
    required DateTime joinedAt,
  }) = _RoomMemberImpl;

  factory RoomMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomMember(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] as String,
      color: jsonSerialization['color'] as int,
      seat: jsonSerialization['seat'] as int,
      connections: jsonSerialization['connections'] as int,
      agreedRound: jsonSerialization['agreedRound'] as int,
      joinedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  String name;

  /// client | dev | guest
  String role;

  int color;

  /// Join order; the lock wave travels around the room in this order.
  int seat;

  /// Open live connections. 0 = left the room / closed the app.
  int connections;

  /// Agreed to the scope in this round (see ScopeRoom.round).
  int agreedRound;

  DateTime joinedAt;

  /// Returns a shallow copy of this [RoomMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RoomMember copyWith({
    int? id,
    int? roomId,
    String? name,
    String? role,
    int? color,
    int? seat,
    int? connections,
    int? agreedRound,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomMember',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'role': role,
      'color': color,
      'seat': seat,
      'connections': connections,
      'agreedRound': agreedRound,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RoomMember',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'role': role,
      'color': color,
      'seat': seat,
      'connections': connections,
      'agreedRound': agreedRound,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomMemberImpl extends RoomMember {
  _RoomMemberImpl({
    int? id,
    required int roomId,
    required String name,
    required String role,
    required int color,
    required int seat,
    required int connections,
    required int agreedRound,
    required DateTime joinedAt,
  }) : super._(
         id: id,
         roomId: roomId,
         name: name,
         role: role,
         color: color,
         seat: seat,
         connections: connections,
         agreedRound: agreedRound,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [RoomMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RoomMember copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? name,
    String? role,
    int? color,
    int? seat,
    int? connections,
    int? agreedRound,
    DateTime? joinedAt,
  }) {
    return RoomMember(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      role: role ?? this.role,
      color: color ?? this.color,
      seat: seat ?? this.seat,
      connections: connections ?? this.connections,
      agreedRound: agreedRound ?? this.agreedRound,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
