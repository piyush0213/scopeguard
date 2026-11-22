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
import 'package:scopeguard_app_server/src/generated/protocol.dart' as _iyadfrzi;
import 'package:serverpod/serverpod.dart' as _is;

/// The synchronized "scope locked" wave: each phone lights up in seat order from startAt (server clock).
abstract class LockMoment
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LockMoment._({
    required this.startAt,
    required this.stepMs,
    required this.order,
  });

  factory LockMoment({
    required DateTime startAt,
    required int stepMs,
    required List<int> order,
  }) = _LockMomentImpl;

  factory LockMoment.fromJson(Map<String, dynamic> jsonSerialization) {
    return LockMoment(
      startAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['startAt']),
      stepMs: jsonSerialization['stepMs'] as int,
      order: _iyadfrzi.Protocol().deserialize<List<int>>(
        jsonSerialization['order'],
      ),
    );
  }

  DateTime startAt;

  int stepMs;

  /// Member ids in wave order.
  List<int> order;

  /// Returns a shallow copy of this [LockMoment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LockMoment copyWith({
    DateTime? startAt,
    int? stepMs,
    List<int>? order,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LockMoment',
      'startAt': startAt.toJson(),
      'stepMs': stepMs,
      'order': order.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LockMoment',
      'startAt': startAt.toJson(),
      'stepMs': stepMs,
      'order': order.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _LockMomentImpl extends LockMoment {
  _LockMomentImpl({
    required DateTime startAt,
    required int stepMs,
    required List<int> order,
  }) : super._(
         startAt: startAt,
         stepMs: stepMs,
         order: order,
       );

  /// Returns a shallow copy of this [LockMoment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LockMoment copyWith({
    DateTime? startAt,
    int? stepMs,
    List<int>? order,
  }) {
    return LockMoment(
      startAt: startAt ?? this.startAt,
      stepMs: stepMs ?? this.stepMs,
      order: order ?? this.order.map((e0) => e0).toList(),
    );
  }
}
