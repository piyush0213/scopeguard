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

/// Permanent record: who agreed, in person, to exactly which version of the scope.
abstract class ScopeAgreement
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ScopeAgreement._({
    this.id,
    required this.roomId,
    required this.orderId,
    required this.quoteVersion,
    required this.totalCents,
    required this.fingerprint,
    required this.signers,
    required this.createdAt,
  });

  factory ScopeAgreement({
    int? id,
    required int roomId,
    required String orderId,
    required int quoteVersion,
    required int totalCents,
    required String fingerprint,
    required List<String> signers,
    required DateTime createdAt,
  }) = _ScopeAgreementImpl;

  factory ScopeAgreement.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScopeAgreement(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      orderId: jsonSerialization['orderId'] as String,
      quoteVersion: jsonSerialization['quoteVersion'] as int,
      totalCents: jsonSerialization['totalCents'] as int,
      fingerprint: jsonSerialization['fingerprint'] as String,
      signers: _imf57qlp.Protocol().deserialize<List<String>>(
        jsonSerialization['signers'],
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  String orderId;

  int quoteVersion;

  int totalCents;

  String fingerprint;

  /// "Asha (client)", "Ravi (dev)", ...
  List<String> signers;

  DateTime createdAt;

  /// Returns a shallow copy of this [ScopeAgreement]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ScopeAgreement copyWith({
    int? id,
    int? roomId,
    String? orderId,
    int? quoteVersion,
    int? totalCents,
    String? fingerprint,
    List<String>? signers,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScopeAgreement',
      if (id != null) 'id': id,
      'roomId': roomId,
      'orderId': orderId,
      'quoteVersion': quoteVersion,
      'totalCents': totalCents,
      'fingerprint': fingerprint,
      'signers': signers.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ScopeAgreement',
      if (id != null) 'id': id,
      'roomId': roomId,
      'orderId': orderId,
      'quoteVersion': quoteVersion,
      'totalCents': totalCents,
      'fingerprint': fingerprint,
      'signers': signers.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScopeAgreementImpl extends ScopeAgreement {
  _ScopeAgreementImpl({
    int? id,
    required int roomId,
    required String orderId,
    required int quoteVersion,
    required int totalCents,
    required String fingerprint,
    required List<String> signers,
    required DateTime createdAt,
  }) : super._(
         id: id,
         roomId: roomId,
         orderId: orderId,
         quoteVersion: quoteVersion,
         totalCents: totalCents,
         fingerprint: fingerprint,
         signers: signers,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScopeAgreement]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ScopeAgreement copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? orderId,
    int? quoteVersion,
    int? totalCents,
    String? fingerprint,
    List<String>? signers,
    DateTime? createdAt,
  }) {
    return ScopeAgreement(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      orderId: orderId ?? this.orderId,
      quoteVersion: quoteVersion ?? this.quoteVersion,
      totalCents: totalCents ?? this.totalCents,
      fingerprint: fingerprint ?? this.fingerprint,
      signers: signers ?? this.signers.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
