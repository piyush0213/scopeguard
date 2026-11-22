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
import 'package:serverpod/serverpod.dart' as _is;

/// Returned when you open or join a room. Keep the token on this device.
abstract class RoomTicket
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RoomTicket._({
    required this.code,
    required this.memberId,
    required this.token,
  });

  factory RoomTicket({
    required String code,
    required int memberId,
    required String token,
  }) = _RoomTicketImpl;

  factory RoomTicket.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomTicket(
      code: jsonSerialization['code'] as String,
      memberId: jsonSerialization['memberId'] as int,
      token: jsonSerialization['token'] as String,
    );
  }

  String code;

  int memberId;

  String token;

  /// Returns a shallow copy of this [RoomTicket]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RoomTicket copyWith({
    String? code,
    int? memberId,
    String? token,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomTicket',
      'code': code,
      'memberId': memberId,
      'token': token,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RoomTicket',
      'code': code,
      'memberId': memberId,
      'token': token,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RoomTicketImpl extends RoomTicket {
  _RoomTicketImpl({
    required String code,
    required int memberId,
    required String token,
  }) : super._(
         code: code,
         memberId: memberId,
         token: token,
       );

  /// Returns a shallow copy of this [RoomTicket]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RoomTicket copyWith({
    String? code,
    int? memberId,
    String? token,
  }) {
    return RoomTicket(
      code: code ?? this.code,
      memberId: memberId ?? this.memberId,
      token: token ?? this.token,
    );
  }
}
