/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'scope_room/lock_moment.dart' as _iup9pigm;
import 'scope_room/room_member.dart' as _iy9r7pxd;
import 'scope_room/room_protocol.dart' as _iebi3l3b;
import 'scope_room/room_state.dart' as _iznwphww;
import 'scope_room/scope_agreement.dart' as _i1jcnoa7;
import 'scope_room/scope_room.dart' as _i2o3az2v;
import 'scopeguard/sg_exception.dart' as _izof7ego;
import 'scopeguard/sg_session.dart' as _iwrmxxka;
export 'scope_room/lock_moment.dart';
export 'scope_room/room_member.dart';
export 'scope_room/room_protocol.dart';
export 'scope_room/room_state.dart';
export 'scope_room/scope_agreement.dart';
export 'scope_room/scope_room.dart';
export 'scopeguard/sg_exception.dart';
export 'scopeguard/sg_session.dart';

class Protocol extends _is.DatabaseSerializationManager
    implements _is.DatabaseProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  _is.ProtocolDeserialization get deserializationMetadata =>
      _is.ProtocolDeserialization.cached(
        this,
        types: const [
          _is.getType<_iup9pigm.LockMoment>,
          _is.getType<_iy9r7pxd.RoomMember>,
          _is.getType<_iebi3l3b.RoomTicket>,
          _is.getType<_iznwphww.RoomState>,
          _is.getType<_i1jcnoa7.ScopeAgreement>,
          _is.getType<_i2o3az2v.ScopeRoom>,
          _is.getType<_izof7ego.SgException>,
          _is.getType<_iwrmxxka.SgSession>,
          _is.getType<_iup9pigm.LockMoment?>,
          _is.getType<_iy9r7pxd.RoomMember?>,
          _is.getType<_iebi3l3b.RoomTicket?>,
          _is.getType<_iznwphww.RoomState?>,
          _is.getType<_i1jcnoa7.ScopeAgreement?>,
          _is.getType<_i2o3az2v.ScopeRoom?>,
          _is.getType<_izof7ego.SgException?>,
          _is.getType<_iwrmxxka.SgSession?>,
          _is.getType<List<int>>,
          _is.getType<List<_iy9r7pxd.RoomMember>>,
          _is.getType<List<String>>,
          _is.getType<List<String>>,
        ],
        modules: const [_isp.Protocol.new],
        classNames: const [
          'LockMoment',
          'RoomMember',
          'RoomTicket',
          'RoomState',
          'ScopeAgreement',
          'ScopeRoom',
          'SgException',
          'SgSession',
        ],
      );

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    ..._ownTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static List<_isp.TableDefinition> get _ownTableDefinitions => [
    _isp.TableDefinition(
      name: 'room_member',
      dartName: 'RoomMember',
      schema: 'public',
      module: 'scopeguard_app',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'roomId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'color',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'seat',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'connections',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'agreedRound',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'joinedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'token',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sgToken',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'room_member_room_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'roomId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'scope_agreement',
      dartName: 'ScopeAgreement',
      schema: 'public',
      module: 'scopeguard_app',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'roomId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'orderId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'quoteVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'totalCents',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fingerprint',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'signers',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'scope_agreement_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'orderId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'scope_room',
      dartName: 'ScopeRoom',
      schema: 'public',
      module: 'scopeguard_app',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'orderId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'hostMemberId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'round',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fingerprint',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'momentAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'hostToken',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'scope_room_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
  ];

  static String? getClassNameFromObjectJson(dynamic data) =>
      _is.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _is.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _iup9pigm.LockMoment) {
      return _iup9pigm.LockMoment.fromJson(data) as T;
    }
    if (t == _iy9r7pxd.RoomMember) {
      return _iy9r7pxd.RoomMember.fromJson(data) as T;
    }
    if (t == _iebi3l3b.RoomTicket) {
      return _iebi3l3b.RoomTicket.fromJson(data) as T;
    }
    if (t == _iznwphww.RoomState) {
      return _iznwphww.RoomState.fromJson(data) as T;
    }
    if (t == _i1jcnoa7.ScopeAgreement) {
      return _i1jcnoa7.ScopeAgreement.fromJson(data) as T;
    }
    if (t == _i2o3az2v.ScopeRoom) {
      return _i2o3az2v.ScopeRoom.fromJson(data) as T;
    }
    if (t == _izof7ego.SgException) {
      return _izof7ego.SgException.fromJson(data) as T;
    }
    if (t == _iwrmxxka.SgSession) {
      return _iwrmxxka.SgSession.fromJson(data) as T;
    }
    if (t == _is.getType<_iup9pigm.LockMoment?>()) {
      return (data != null ? _iup9pigm.LockMoment.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy9r7pxd.RoomMember?>()) {
      return (data != null ? _iy9r7pxd.RoomMember.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iebi3l3b.RoomTicket?>()) {
      return (data != null ? _iebi3l3b.RoomTicket.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iznwphww.RoomState?>()) {
      return (data != null ? _iznwphww.RoomState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1jcnoa7.ScopeAgreement?>()) {
      return (data != null ? _i1jcnoa7.ScopeAgreement.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i2o3az2v.ScopeRoom?>()) {
      return (data != null ? _i2o3az2v.ScopeRoom.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izof7ego.SgException?>()) {
      return (data != null ? _izof7ego.SgException.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwrmxxka.SgSession?>()) {
      return (data != null ? _iwrmxxka.SgSession.fromJson(data) : null) as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_iy9r7pxd.RoomMember>) {
      return (data as List)
              .map((e) => deserialize<_iy9r7pxd.RoomMember>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    final modules = deserializationMetadata.modulesForDeserialization(
      t,
      className: rawDataClassName,
    );
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _is.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iup9pigm.LockMoment => 'LockMoment',
      _iy9r7pxd.RoomMember => 'RoomMember',
      _iebi3l3b.RoomTicket => 'RoomTicket',
      _iznwphww.RoomState => 'RoomState',
      _i1jcnoa7.ScopeAgreement => 'ScopeAgreement',
      _i2o3az2v.ScopeRoom => 'ScopeRoom',
      _izof7ego.SgException => 'SgException',
      _iwrmxxka.SgSession => 'SgSession',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'scopeguard_app.',
        '',
      );
    }

    switch (data) {
      case _iup9pigm.LockMoment():
        return 'LockMoment';
      case _iy9r7pxd.RoomMember():
        return 'RoomMember';
      case _iebi3l3b.RoomTicket():
        return 'RoomTicket';
      case _iznwphww.RoomState():
        return 'RoomState';
      case _i1jcnoa7.ScopeAgreement():
        return 'ScopeAgreement';
      case _i2o3az2v.ScopeRoom():
        return 'ScopeRoom';
      case _izof7ego.SgException():
        return 'SgException';
      case _iwrmxxka.SgSession():
        return 'SgSession';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'LockMoment') {
      return deserialize<_iup9pigm.LockMoment>(data['data']);
    }
    if (dataClassName == 'RoomMember') {
      return deserialize<_iy9r7pxd.RoomMember>(data['data']);
    }
    if (dataClassName == 'RoomTicket') {
      return deserialize<_iebi3l3b.RoomTicket>(data['data']);
    }
    if (dataClassName == 'RoomState') {
      return deserialize<_iznwphww.RoomState>(data['data']);
    }
    if (dataClassName == 'ScopeAgreement') {
      return deserialize<_i1jcnoa7.ScopeAgreement>(data['data']);
    }
    if (dataClassName == 'ScopeRoom') {
      return deserialize<_i2o3az2v.ScopeRoom>(data['data']);
    }
    if (dataClassName == 'SgException') {
      return deserialize<_izof7ego.SgException>(data['data']);
    }
    if (dataClassName == 'SgSession') {
      return deserialize<_iwrmxxka.SgSession>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      return _isp.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(10),
      });
    }
    return super.deserializeByClassName(data);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _iy9r7pxd.RoomMember:
        return _iy9r7pxd.RoomMember.t;
      case _i1jcnoa7.ScopeAgreement:
        return _i1jcnoa7.ScopeAgreement.t;
      case _i2o3az2v.ScopeRoom:
        return _i2o3az2v.ScopeRoom.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  List<_isp.TableDefinition> getOwnTableDefinitions() => _ownTableDefinitions;

  @override
  String getModuleName() => 'scopeguard_app';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _isp.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
