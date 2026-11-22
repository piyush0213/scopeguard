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
import 'package:scopeguard_app_server/src/generated/protocol.dart' as _iyadfrzi;
import 'package:serverpod/serverpod.dart' as _is;

/// Permanent record: who agreed, in person, to exactly which version of the scope.
abstract class ScopeAgreement
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
      signers: _iyadfrzi.Protocol().deserialize<List<String>>(
        jsonSerialization['signers'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ScopeAgreementTable();

  static const db = ScopeAgreementRepository._();

  @override
  int? id;

  int roomId;

  String orderId;

  int quoteVersion;

  int totalCents;

  String fingerprint;

  /// "Asha (client)", "Ravi (dev)", ...
  List<String> signers;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ScopeAgreement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static ScopeAgreementInclude include() {
    return ScopeAgreementInclude._();
  }

  static ScopeAgreementIncludeList includeList({
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    ScopeAgreementInclude? include,
  }) {
    return ScopeAgreementIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class ScopeAgreementUpdateTable extends _is.UpdateTable<ScopeAgreementTable> {
  ScopeAgreementUpdateTable(super.table);

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<String, String> orderId(String value) => _is.ColumnValue(
    table.orderId,
    value,
  );

  _is.ColumnValue<int, int> quoteVersion(int value) => _is.ColumnValue(
    table.quoteVersion,
    value,
  );

  _is.ColumnValue<int, int> totalCents(int value) => _is.ColumnValue(
    table.totalCents,
    value,
  );

  _is.ColumnValue<String, String> fingerprint(String value) => _is.ColumnValue(
    table.fingerprint,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> signers(List<String> value) =>
      _is.ColumnValue(
        table.signers,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScopeAgreementTable extends _is.Table<int?> {
  ScopeAgreementTable({super.tableRelation})
    : super(tableName: 'scope_agreement') {
    updateTable = ScopeAgreementUpdateTable(this);
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    orderId = _is.ColumnString(
      'orderId',
      this,
    );
    quoteVersion = _is.ColumnInt(
      'quoteVersion',
      this,
    );
    totalCents = _is.ColumnInt(
      'totalCents',
      this,
    );
    fingerprint = _is.ColumnString(
      'fingerprint',
      this,
    );
    signers = _is.ColumnSerializable<List<String>>(
      'signers',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScopeAgreementUpdateTable updateTable;

  late final _is.ColumnInt roomId;

  late final _is.ColumnString orderId;

  late final _is.ColumnInt quoteVersion;

  late final _is.ColumnInt totalCents;

  late final _is.ColumnString fingerprint;

  /// "Asha (client)", "Ravi (dev)", ...
  late final _is.ColumnSerializable<List<String>> signers;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    roomId,
    orderId,
    quoteVersion,
    totalCents,
    fingerprint,
    signers,
    createdAt,
  ];
}

class ScopeAgreementInclude extends _is.IncludeObject {
  ScopeAgreementInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ScopeAgreement.t;
}

class ScopeAgreementIncludeList extends _is.IncludeList {
  ScopeAgreementIncludeList._({
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScopeAgreement.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ScopeAgreement.t;
}

class ScopeAgreementRepository {
  const ScopeAgreementRepository._();

  /// Returns a list of [ScopeAgreement]s matching the given query parameters.
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
  Future<List<ScopeAgreement>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScopeAgreement>(
      where: where?.call(ScopeAgreement.t),
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScopeAgreement]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScopeAgreement.t`.
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
  _ida.Stream<List<ScopeAgreement>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScopeAgreement>(
      where: where?.call(ScopeAgreement.t),
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScopeAgreement] matching the given query parameters.
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
  Future<ScopeAgreement?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    int? offset,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScopeAgreement>(
      where: where?.call(ScopeAgreement.t),
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScopeAgreement] by its [id] or null if no such row exists.
  Future<ScopeAgreement?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScopeAgreement>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScopeAgreement]s in the list and returns the inserted rows.
  ///
  /// The returned [ScopeAgreement]s will have their `id` fields set.
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
  Future<List<ScopeAgreement>> insert(
    _is.DatabaseSession session,
    List<ScopeAgreement> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScopeAgreement>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScopeAgreement] and returns the inserted row.
  ///
  /// The returned [ScopeAgreement] will have its `id` field set.
  Future<ScopeAgreement> insertRow(
    _is.DatabaseSession session,
    ScopeAgreement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScopeAgreement>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScopeAgreement]s in the list and returns the resulting rows.
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
  /// The returned [ScopeAgreement]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeAgreement>> upsert(
    _is.DatabaseSession session,
    List<ScopeAgreement> rows, {
    required _is.ColumnSelections<ScopeAgreementTable> conflictColumns,
    _is.ColumnSelections<ScopeAgreementTable>? updateColumns,
    _is.WhereExpressionBuilder<ScopeAgreementTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScopeAgreement>(
      rows,
      conflictColumns: conflictColumns(ScopeAgreement.t),
      updateColumns: updateColumns?.call(ScopeAgreement.t),
      updateWhere: updateWhere?.call(ScopeAgreement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScopeAgreement] and returns the resulting row.
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
  /// The returned [ScopeAgreement] will have its `id` field set.
  Future<ScopeAgreement?> upsertRow(
    _is.DatabaseSession session,
    ScopeAgreement row, {
    required _is.ColumnSelections<ScopeAgreementTable> conflictColumns,
    _is.ColumnSelections<ScopeAgreementTable>? updateColumns,
    _is.WhereExpressionBuilder<ScopeAgreementTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScopeAgreement>(
      row,
      conflictColumns: conflictColumns(ScopeAgreement.t),
      updateColumns: updateColumns?.call(ScopeAgreement.t),
      updateWhere: updateWhere?.call(ScopeAgreement.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScopeAgreement]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeAgreement>> update(
    _is.DatabaseSession session,
    List<ScopeAgreement> rows, {
    _is.ColumnSelections<ScopeAgreementTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScopeAgreement>(
      rows,
      columns: columns?.call(ScopeAgreement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScopeAgreement]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScopeAgreement> updateRow(
    _is.DatabaseSession session,
    ScopeAgreement row, {
    _is.ColumnSelections<ScopeAgreementTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScopeAgreement>(
      row,
      columns: columns?.call(ScopeAgreement.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScopeAgreement] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScopeAgreement?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ScopeAgreementUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScopeAgreement>(
      id,
      columnValues: columnValues(ScopeAgreement.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScopeAgreement]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScopeAgreement>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScopeAgreementUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScopeAgreementTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScopeAgreement>(
      columnValues: columnValues(ScopeAgreement.t.updateTable),
      where: where(ScopeAgreement.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScopeAgreement]s in the list and returns the deleted rows.
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
  Future<List<ScopeAgreement>> delete(
    _is.DatabaseSession session,
    List<ScopeAgreement> rows, {
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScopeAgreement>(
      rows,
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScopeAgreement].
  Future<ScopeAgreement> deleteRow(
    _is.DatabaseSession session,
    ScopeAgreement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScopeAgreement>(
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
  Future<List<ScopeAgreement>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScopeAgreementTable> where,
    _is.OrderByBuilder<ScopeAgreementTable>? orderBy,
    _is.OrderByListBuilder<ScopeAgreementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScopeAgreement>(
      where: where(ScopeAgreement.t),
      orderBy: orderBy?.call(ScopeAgreement.t),
      orderByList: orderByList?.call(ScopeAgreement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScopeAgreementTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScopeAgreement>(
      where: where?.call(ScopeAgreement.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScopeAgreement] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScopeAgreementTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScopeAgreement>(
      where: where(ScopeAgreement.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
