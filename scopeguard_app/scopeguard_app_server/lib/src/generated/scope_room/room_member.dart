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

/// Someone in the room. Signed-in ScopeGuard users get their real role; anyone else joins as a guest
/// (e.g. the client's co-founder) with just a name.
abstract class RoomMember
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    this.token,
    this.sgToken,
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
    String? token,
    String? sgToken,
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
      joinedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      token: jsonSerialization['token'] as String?,
      sgToken: jsonSerialization['sgToken'] as String?,
    );
  }

  static final t = RoomMemberTable();

  static const db = RoomMemberRepository._();

  @override
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

  /// Secret that authorizes this member's actions in the room.
  String? token;

  /// This member's own ScopeGuard sign-in, if any (lets a client switch items on the bill). Server only.
  String? sgToken;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [RoomMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    String? token,
    String? sgToken,
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
      if (token != null) 'token': token,
      if (sgToken != null) 'sgToken': sgToken,
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

  static RoomMemberInclude include() {
    return RoomMemberInclude._();
  }

  static RoomMemberIncludeList includeList({
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    RoomMemberInclude? include,
  }) {
    return RoomMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    String? token,
    String? sgToken,
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
         token: token,
         sgToken: sgToken,
       );

  /// Returns a shallow copy of this [RoomMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    Object? token = _Undefined,
    Object? sgToken = _Undefined,
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
      token: token is String? ? token : this.token,
      sgToken: sgToken is String? ? sgToken : this.sgToken,
    );
  }
}

class RoomMemberUpdateTable extends _is.UpdateTable<RoomMemberTable> {
  RoomMemberUpdateTable(super.table);

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> role(String value) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<int, int> color(int value) => _is.ColumnValue(
    table.color,
    value,
  );

  _is.ColumnValue<int, int> seat(int value) => _is.ColumnValue(
    table.seat,
    value,
  );

  _is.ColumnValue<int, int> connections(int value) => _is.ColumnValue(
    table.connections,
    value,
  );

  _is.ColumnValue<int, int> agreedRound(int value) => _is.ColumnValue(
    table.agreedRound,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _is.ColumnValue(
        table.joinedAt,
        value,
      );

  _is.ColumnValue<String, String> token(String? value) => _is.ColumnValue(
    table.token,
    value,
  );

  _is.ColumnValue<String, String> sgToken(String? value) => _is.ColumnValue(
    table.sgToken,
    value,
  );
}

class RoomMemberTable extends _is.Table<int?> {
  RoomMemberTable({super.tableRelation}) : super(tableName: 'room_member') {
    updateTable = RoomMemberUpdateTable(this);
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    role = _is.ColumnString(
      'role',
      this,
    );
    color = _is.ColumnInt(
      'color',
      this,
    );
    seat = _is.ColumnInt(
      'seat',
      this,
    );
    connections = _is.ColumnInt(
      'connections',
      this,
    );
    agreedRound = _is.ColumnInt(
      'agreedRound',
      this,
    );
    joinedAt = _is.ColumnDateTime(
      'joinedAt',
      this,
    );
    token = _is.ColumnString(
      'token',
      this,
    );
    sgToken = _is.ColumnString(
      'sgToken',
      this,
    );
  }

  late final RoomMemberUpdateTable updateTable;

  late final _is.ColumnInt roomId;

  late final _is.ColumnString name;

  /// client | dev | guest
  late final _is.ColumnString role;

  late final _is.ColumnInt color;

  /// Join order; the lock wave travels around the room in this order.
  late final _is.ColumnInt seat;

  /// Open live connections. 0 = left the room / closed the app.
  late final _is.ColumnInt connections;

  /// Agreed to the scope in this round (see ScopeRoom.round).
  late final _is.ColumnInt agreedRound;

  late final _is.ColumnDateTime joinedAt;

  /// Secret that authorizes this member's actions in the room.
  late final _is.ColumnString token;

  /// This member's own ScopeGuard sign-in, if any (lets a client switch items on the bill). Server only.
  late final _is.ColumnString sgToken;

  @override
  List<_is.Column> get columns => [
    id,
    roomId,
    name,
    role,
    color,
    seat,
    connections,
    agreedRound,
    joinedAt,
    token,
    sgToken,
  ];
}

class RoomMemberInclude extends _is.IncludeObject {
  RoomMemberInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => RoomMember.t;
}

class RoomMemberIncludeList extends _is.IncludeList {
  RoomMemberIncludeList._({
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RoomMember.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => RoomMember.t;
}

class RoomMemberRepository {
  const RoomMemberRepository._();

  /// Returns a list of [RoomMember]s matching the given query parameters.
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
  Future<List<RoomMember>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RoomMember>(
      where: where?.call(RoomMember.t),
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [RoomMember]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `RoomMember.t`.
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
  _ida.Stream<List<RoomMember>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<RoomMember>(
      where: where?.call(RoomMember.t),
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [RoomMember] matching the given query parameters.
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
  Future<RoomMember?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    int? offset,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RoomMember>(
      where: where?.call(RoomMember.t),
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RoomMember] by its [id] or null if no such row exists.
  Future<RoomMember?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RoomMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RoomMember]s in the list and returns the inserted rows.
  ///
  /// The returned [RoomMember]s will have their `id` fields set.
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
  Future<List<RoomMember>> insert(
    _is.DatabaseSession session,
    List<RoomMember> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RoomMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RoomMember] and returns the inserted row.
  ///
  /// The returned [RoomMember] will have its `id` field set.
  Future<RoomMember> insertRow(
    _is.DatabaseSession session,
    RoomMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RoomMember>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RoomMember]s in the list and returns the resulting rows.
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
  /// The returned [RoomMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RoomMember>> upsert(
    _is.DatabaseSession session,
    List<RoomMember> rows, {
    required _is.ColumnSelections<RoomMemberTable> conflictColumns,
    _is.ColumnSelections<RoomMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<RoomMemberTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RoomMember>(
      rows,
      conflictColumns: conflictColumns(RoomMember.t),
      updateColumns: updateColumns?.call(RoomMember.t),
      updateWhere: updateWhere?.call(RoomMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RoomMember] and returns the resulting row.
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
  /// The returned [RoomMember] will have its `id` field set.
  Future<RoomMember?> upsertRow(
    _is.DatabaseSession session,
    RoomMember row, {
    required _is.ColumnSelections<RoomMemberTable> conflictColumns,
    _is.ColumnSelections<RoomMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<RoomMemberTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RoomMember>(
      row,
      conflictColumns: conflictColumns(RoomMember.t),
      updateColumns: updateColumns?.call(RoomMember.t),
      updateWhere: updateWhere?.call(RoomMember.t),
      transaction: transaction,
    );
  }

  /// Updates all [RoomMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RoomMember>> update(
    _is.DatabaseSession session,
    List<RoomMember> rows, {
    _is.ColumnSelections<RoomMemberTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RoomMember>(
      rows,
      columns: columns?.call(RoomMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RoomMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RoomMember> updateRow(
    _is.DatabaseSession session,
    RoomMember row, {
    _is.ColumnSelections<RoomMemberTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RoomMember>(
      row,
      columns: columns?.call(RoomMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RoomMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RoomMember?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RoomMemberUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RoomMember>(
      id,
      columnValues: columnValues(RoomMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RoomMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RoomMember>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RoomMemberUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RoomMemberTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RoomMember>(
      columnValues: columnValues(RoomMember.t.updateTable),
      where: where(RoomMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RoomMember]s in the list and returns the deleted rows.
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
  Future<List<RoomMember>> delete(
    _is.DatabaseSession session,
    List<RoomMember> rows, {
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RoomMember>(
      rows,
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RoomMember].
  Future<RoomMember> deleteRow(
    _is.DatabaseSession session,
    RoomMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RoomMember>(
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
  Future<List<RoomMember>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoomMemberTable> where,
    _is.OrderByBuilder<RoomMemberTable>? orderBy,
    _is.OrderByListBuilder<RoomMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RoomMember>(
      where: where(RoomMember.t),
      orderBy: orderBy?.call(RoomMember.t),
      orderByList: orderByList?.call(RoomMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomMemberTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RoomMember>(
      where: where?.call(RoomMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RoomMember] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoomMemberTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RoomMember>(
      where: where(RoomMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
