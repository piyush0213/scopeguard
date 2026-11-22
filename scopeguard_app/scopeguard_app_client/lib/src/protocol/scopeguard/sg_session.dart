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

/// A signed-in ScopeGuard user. The same account works on the website and in the app.
abstract class SgSession
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SgSession._({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory SgSession({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String role,
  }) = _SgSessionImpl;

  factory SgSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return SgSession(
      token: jsonSerialization['token'] as String,
      userId: jsonSerialization['userId'] as String,
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      role: jsonSerialization['role'] as String,
    );
  }

  String token;

  String userId;

  String name;

  String email;

  /// client | dev
  String role;

  /// Returns a shallow copy of this [SgSession]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SgSession copyWith({
    String? token,
    String? userId,
    String? name,
    String? email,
    String? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SgSession',
      'token': token,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SgSession',
      'token': token,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SgSessionImpl extends SgSession {
  _SgSessionImpl({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String role,
  }) : super._(
         token: token,
         userId: userId,
         name: name,
         email: email,
         role: role,
       );

  /// Returns a shallow copy of this [SgSession]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SgSession copyWith({
    String? token,
    String? userId,
    String? name,
    String? email,
    String? role,
  }) {
    return SgSession(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}
