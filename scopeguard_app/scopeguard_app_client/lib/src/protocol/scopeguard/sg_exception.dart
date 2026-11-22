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

/// An error from ScopeGuard, safe to show to the user as-is.
abstract class SgException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  SgException._({
    required this.message,
    required this.status,
  });

  factory SgException({
    required String message,
    required int status,
  }) = _SgExceptionImpl;

  factory SgException.fromJson(Map<String, dynamic> jsonSerialization) {
    return SgException(
      message: jsonSerialization['message'] as String,
      status: jsonSerialization['status'] as int,
    );
  }

  String message;

  /// HTTP-style status: 400 bad input, 401 signed out, 403 not allowed, 404 missing, 409 wrong state, 503 API down.
  int status;

  /// Returns a shallow copy of this [SgException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SgException copyWith({
    String? message,
    int? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SgException',
      'message': message,
      'status': status,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SgException',
      'message': message,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'SgException(message: $message, status: $status)';
  }
}

class _SgExceptionImpl extends SgException {
  _SgExceptionImpl({
    required String message,
    required int status,
  }) : super._(
         message: message,
         status: status,
       );

  /// Returns a shallow copy of this [SgException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SgException copyWith({
    String? message,
    int? status,
  }) {
    return SgException(
      message: message ?? this.message,
      status: status ?? this.status,
    );
  }
}
