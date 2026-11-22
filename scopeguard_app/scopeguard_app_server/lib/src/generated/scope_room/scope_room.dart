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
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;

/// Scope Room (Track 1 "Here, together"): everyone at the kickoff meeting joins one ScopeGuard order from
/// their own phone, watches the quote change live and agrees to the scope together. Temporary by design.
abstract class ScopeRoom
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    this.hostToken,
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
    String? hostToken,
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
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['momentAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      hostToken: jsonSerialization['hostToken'] as String?,
    );
  }

  static final t = ScopeRoomTable();

  static const db = ScopeRoomRepository._();

  @override
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

  /// ScopeGuard token of whoever opened the room; used to read the order. Never sent to phones.
  String? hostToken;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ScopeRoom]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScopeRoom copyWith({
    int? id,
    String? code,
    String? orderId,
    String? title,
    String? status,
    int? hostMemberId,
    int? round,
    String? fingerprint,
    DateTime? momentAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? expiresAt,
    String? hostToken,
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
      if (hostToken != null) 'hostToken': hostToken,
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

  static ScopeRoomInclude include() {
    return ScopeRoomInclude._();
  }

  static ScopeRoomIncludeList includeList({
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    ScopeRoomInclude? include,
  }) {
    return ScopeRoomIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    String? hostToken,
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
         hostToken: hostToken,
       );

  /// Returns a shallow copy of this [ScopeRoom]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    DateTime? momentAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? hostToken = _Undefined,
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
      momentAt: momentAt is _is.UndefinedSentinel ? this.momentAt : momentAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hostToken: hostToken is String? ? hostToken : this.hostToken,
    );
  }
}

class ScopeRoomUpdateTable extends _is.UpdateTable<ScopeRoomTable> {
  ScopeRoomUpdateTable(super.table);

  _is.ColumnValue<String, String> code(String value) => _is.ColumnValue(
    table.code,
    value,
  );

  _is.ColumnValue<String, String> orderId(String value) => _is.ColumnValue(
    table.orderId,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> hostMemberId(int? value) => _is.ColumnValue(
    table.hostMemberId,
    value,
  );

  _is.ColumnValue<int, int> round(int value) => _is.ColumnValue(
    table.round,
    value,
  );

  _is.ColumnValue<String, String> fingerprint(String? value) => _is.ColumnValue(
    table.fingerprint,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> momentAt(DateTime? value) =>
      _is.ColumnValue(
        table.momentAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<String, String> hostToken(String? value) => _is.ColumnValue(
    table.hostToken,
    value,
  );
}

class ScopeRoomTable extends _is.Table<int?> {
  ScopeRoomTable({super.tableRelation}) : super(tableName: 'scope_room') {
    updateTable = ScopeRoomUpdateTable(this);
    code = _is.ColumnString(
      'code',
      this,
    );
    orderId = _is.ColumnString(
      'orderId',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    hostMemberId = _is.ColumnInt(
      'hostMemberId',
      this,
    );
    round = _is.ColumnInt(
      'round',
      this,
    );
    fingerprint = _is.ColumnString(
      'fingerprint',
      this,
    );
    momentAt = _is.ColumnDateTime(
      'momentAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    hostToken = _is.ColumnString(
      'hostToken',
      this,
    );
  }

  late final ScopeRoomUpdateTable updateTable;

  /// 4-letter join code shown on screen and in the QR.
  late final _is.ColumnString code;

  /// The ScopeGuard order this room negotiates, e.g. CD-1052.
  late final _is.ColumnString orderId;

  late final _is.ColumnString title;

  /// open | agreed | ended
  late final _is.ColumnString status;

  late final _is.ColumnInt hostMemberId;

  /// Bumped whenever the quote changes: earlier "agree" taps no longer count.
  late final _is.ColumnInt round;

  /// sha256 of the quote version + included items + prices that people are agreeing to.
  late final _is.ColumnString fingerprint;

  /// When the synchronized lock wave starts on every phone (server clock).
  late final _is.ColumnDateTime momentAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime expiresAt;

  /// ScopeGuard token of whoever opened the room; used to read the order. Never sent to phones.
  late final _is.ColumnString hostToken;

  @override
  List<_is.Column> get columns => [
    id,
    code,
    orderId,
    title,
    status,
    hostMemberId,
    round,
    fingerprint,
    momentAt,
    createdAt,
    expiresAt,
    hostToken,
  ];
}

class ScopeRoomInclude extends _is.IncludeObject {
  ScopeRoomInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ScopeRoom.t;
}

class ScopeRoomIncludeList extends _is.IncludeList {
  ScopeRoomIncludeList._({
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScopeRoom.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ScopeRoom.t;
}

class ScopeRoomRepository {
  const ScopeRoomRepository._();

  /// Returns a list of [ScopeRoom]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ScopeRoom>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScopeRoom>(
      where: where?.call(ScopeRoom.t),
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScopeRoom]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `ScopeRoom.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<ScopeRoom>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScopeRoom>(
      where: where?.call(ScopeRoom.t),
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScopeRoom] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ScopeRoom?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    int? offset,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScopeRoom>(
      where: where?.call(ScopeRoom.t),
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScopeRoom] by its [id] or null if no such row exists.
  Future<ScopeRoom?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScopeRoom>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScopeRoom]s in the list and returns the inserted rows.
  ///
  /// The returned [ScopeRoom]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> insert(
    _is.DatabaseSession session,
    List<ScopeRoom> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScopeRoom>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScopeRoom] and returns the inserted row.
  ///
  /// The returned [ScopeRoom] will have its `id` field set.
  Future<ScopeRoom> insertRow(
    _is.DatabaseSession session,
    ScopeRoom row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScopeRoom>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScopeRoom]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [ScopeRoom]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> upsert(
    _is.DatabaseSession session,
    List<ScopeRoom> rows, {
    required _is.ColumnSelections<ScopeRoomTable> conflictColumns,
    _is.ColumnSelections<ScopeRoomTable>? updateColumns,
    _is.WhereExpressionBuilder<ScopeRoomTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScopeRoom>(
      rows,
      conflictColumns: conflictColumns(ScopeRoom.t),
      updateColumns: updateColumns?.call(ScopeRoom.t),
      updateWhere: updateWhere?.call(ScopeRoom.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScopeRoom] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [ScopeRoom] will have its `id` field set.
  Future<ScopeRoom?> upsertRow(
    _is.DatabaseSession session,
    ScopeRoom row, {
    required _is.ColumnSelections<ScopeRoomTable> conflictColumns,
    _is.ColumnSelections<ScopeRoomTable>? updateColumns,
    _is.WhereExpressionBuilder<ScopeRoomTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScopeRoom>(
      row,
      conflictColumns: conflictColumns(ScopeRoom.t),
      updateColumns: updateColumns?.call(ScopeRoom.t),
      updateWhere: updateWhere?.call(ScopeRoom.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScopeRoom]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> update(
    _is.DatabaseSession session,
    List<ScopeRoom> rows, {
    _is.ColumnSelections<ScopeRoomTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScopeRoom>(
      rows,
      columns: columns?.call(ScopeRoom.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScopeRoom]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScopeRoom> updateRow(
    _is.DatabaseSession session,
    ScopeRoom row, {
    _is.ColumnSelections<ScopeRoomTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScopeRoom>(
      row,
      columns: columns?.call(ScopeRoom.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScopeRoom] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScopeRoom?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ScopeRoomUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScopeRoom>(
      id,
      columnValues: columnValues(ScopeRoom.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScopeRoom]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScopeRoomUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScopeRoomTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScopeRoom>(
      columnValues: columnValues(ScopeRoom.t.updateTable),
      where: where(ScopeRoom.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScopeRoom]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> delete(
    _is.DatabaseSession session,
    List<ScopeRoom> rows, {
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScopeRoom>(
      rows,
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScopeRoom].
  Future<ScopeRoom> deleteRow(
    _is.DatabaseSession session,
    ScopeRoom row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScopeRoom>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeRoom>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScopeRoomTable> where,
    _is.OrderByBuilder<ScopeRoomTable>? orderBy,
    _is.OrderByListBuilder<ScopeRoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScopeRoom>(
      where: where(ScopeRoom.t),
      orderBy: orderBy?.call(ScopeRoom.t),
      orderByList: orderByList?.call(ScopeRoom.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeRoomTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScopeRoom>(
      where: where?.call(ScopeRoom.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScopeRoom] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScopeRoomTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScopeRoom>(
      where: where(ScopeRoom.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
