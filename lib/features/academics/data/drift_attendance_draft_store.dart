import 'dart:async';

import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/core/storage/campus_local_database.dart';
import 'package:campus_connect/core/storage/local_database_key_store.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final campusLocalDatabaseManagerProvider = Provider<CampusLocalDatabaseManager>(
  (ref) {
    final config = ref.watch(appConfigProvider);
    final namespace = databaseNamespaceFor(config);
    final manager = CampusLocalDatabaseManager(
      config: config,
      keyStore: LocalDatabaseKeyStore(
        ref.watch(sensitiveDataKeyStoreProvider),
        namespace: namespace,
      ),
      logger: ref.watch(appLoggerProvider),
    );
    ref.onDispose(() => unawaited(manager.close()));
    return manager;
  },
);

final attendanceDraftStoreProvider = Provider<AttendanceDraftStore>(
  (ref) => DriftAttendanceDraftStore(
    ref.watch(campusLocalDatabaseManagerProvider),
    ref.watch(appLoggerProvider),
  ),
);

class DriftAttendanceDraftStore implements AttendanceDraftStore {
  DriftAttendanceDraftStore(
    this._databaseManager,
    this._logger, {
    String Function()? idFactory,
  }) : _idFactory = idFactory ?? const Uuid().v4;

  static const _payloadVersion = 1;

  final CampusLocalDatabaseManager _databaseManager;
  final AppLogger _logger;
  final String Function() _idFactory;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<List<AttendanceDraft>> loadAll() => _enqueue(() async {
    final database = await _databaseManager.open();
    try {
      return database.transaction(() async {
        final draftRows = await database
            .select(database.attendanceDraftRows)
            .get();
        final markRows = await database
            .select(database.attendanceDraftMarkRows)
            .get();
        final marksByDraft = <String, List<AttendanceDraftMarkRow>>{};
        for (final mark in markRows) {
          (marksByDraft[mark.draftId] ??= []).add(mark);
        }

        final drafts = <AttendanceDraft>[];
        final invalidIds = <String>[];
        for (final row in draftRows) {
          final draft = _decode(row, marksByDraft[row.id] ?? const []);
          if (draft == null) {
            invalidIds.add(row.id);
          } else {
            drafts.add(draft);
          }
        }
        if (invalidIds.isNotEmpty) {
          await (database.delete(
            database.attendanceDraftRows,
          )..where((row) => row.id.isIn(invalidIds))).go();
          _logger.warning('attendance.draft.invalid_rows_discarded');
        }
        drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return List.unmodifiable(drafts);
      });
    } on Object catch (error, stackTrace) {
      _logger.error(
        'attendance.draft.encrypted_store_read_failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  });

  @override
  Future<void> upsert(AttendanceDraft draft) => _enqueue(() async {
    _validate(draft);
    final database = await _databaseManager.open();
    await database.transaction(() async {
      final existing =
          await (database.select(database.attendanceDraftRows)
                ..where((row) => row.scopeKey.equals(draft.storageKey)))
              .getSingleOrNull();
      final id = existing?.id ?? _idFactory();
      await database
          .into(database.attendanceDraftRows)
          .insertOnConflictUpdate(
            AttendanceDraftRowsCompanion.insert(
              id: id,
              scopeKey: draft.storageKey,
              payloadVersion: _payloadVersion,
              userId: draft.userId,
              membershipId: draft.membershipId,
              institutionId: draft.institutionId,
              selectionKey: draft.selectionKey,
              courseOfferingId: draft.courseOfferingId,
              timetableEntryId: draft.timetableEntryId,
              subjectCode: draft.subjectCode,
              subjectName: draft.subjectName,
              startsAt: draft.startsAt,
              endsAt: draft.endsAt,
              sessionDate: attendanceDateKey(draft.sessionDate),
              state: _encodeState(draft.state),
              requestId: Value(draft.requestId),
              createdAtUtc: draft.createdAt.toUtc(),
              updatedAtUtc: draft.updatedAt.toUtc(),
            ),
          );
      await (database.delete(
        database.attendanceDraftMarkRows,
      )..where((row) => row.draftId.equals(id))).go();
      await database.batch((batch) {
        batch.insertAll(database.attendanceDraftMarkRows, [
          for (final rosterMember in draft.roster)
            AttendanceDraftMarkRowsCompanion.insert(
              draftId: id,
              enrolmentId: rosterMember.enrolmentId,
              studentUserId: rosterMember.userId,
              status: draft.statuses[rosterMember.userId]!.databaseKey,
            ),
        ]);
      });
    });
  });

  @override
  Future<void> delete(String storageKey) => _enqueue(() async {
    final database = await _databaseManager.open();
    await (database.delete(
      database.attendanceDraftRows,
    )..where((row) => row.scopeKey.equals(storageKey))).go();
  });

  @override
  Future<void> deleteForUser(String userId) => _enqueue(() async {
    final database = await _databaseManager.open();
    await (database.delete(
      database.attendanceDraftRows,
    )..where((row) => row.userId.equals(userId))).go();
  });

  @override
  Future<void> deleteAll() => _enqueue(_databaseManager.destroy);

  AttendanceDraft? _decode(
    AttendanceDraftRow row,
    List<AttendanceDraftMarkRow> marks,
  ) {
    final date = DateTime.tryParse(row.sessionDate);
    if (date == null || attendanceDateKey(date) != row.sessionDate) return null;
    if (marks.isEmpty) return null;

    final roster = <AttendanceDraftRosterMember>[];
    final statuses = <String, AttendanceStatus>{};
    final enrolmentIds = <String>{};
    for (final mark in marks) {
      final status = AttendanceStatus.fromDatabaseValue(mark.status);
      if (status == null ||
          !enrolmentIds.add(mark.enrolmentId) ||
          statuses.containsKey(mark.studentUserId)) {
        return null;
      }
      roster.add(
        AttendanceDraftRosterMember(
          enrolmentId: mark.enrolmentId,
          userId: mark.studentUserId,
        ),
      );
      statuses[mark.studentUserId] = status;
    }
    roster.sort((a, b) {
      final userComparison = a.userId.compareTo(b.userId);
      return userComparison != 0
          ? userComparison
          : a.enrolmentId.compareTo(b.enrolmentId);
    });

    var state = _decodeState(row.state);
    if (state == null ||
        row.payloadVersion != _payloadVersion ||
        (state == AttendanceDraftState.submissionUncertain &&
            (row.requestId == null || row.requestId!.isEmpty)) ||
        (state != AttendanceDraftState.submissionUncertain &&
            row.requestId != null)) {
      state = AttendanceDraftState.needsReview;
    }
    final draft = AttendanceDraft(
      userId: row.userId,
      membershipId: row.membershipId,
      institutionId: row.institutionId,
      selectionKey: row.selectionKey,
      courseOfferingId: row.courseOfferingId,
      timetableEntryId: row.timetableEntryId,
      subjectCode: row.subjectCode,
      subjectName: row.subjectName,
      startsAt: row.startsAt,
      endsAt: row.endsAt,
      sessionDate: date,
      roster: roster,
      statuses: statuses,
      state: state,
      requestId: state == AttendanceDraftState.submissionUncertain
          ? row.requestId
          : null,
      createdAt: row.createdAtUtc.toUtc(),
      updatedAt: row.updatedAtUtc.toUtc(),
    );
    try {
      _validate(draft);
    } on FormatException {
      return null;
    }
    return draft.storageKey == row.scopeKey ? draft : null;
  }

  void _validate(AttendanceDraft draft) {
    if (draft.userId.isEmpty ||
        draft.membershipId.isEmpty ||
        draft.institutionId.isEmpty ||
        draft.selectionKey.isEmpty ||
        draft.courseOfferingId.isEmpty ||
        draft.timetableEntryId.isEmpty ||
        draft.subjectCode.isEmpty ||
        draft.subjectName.isEmpty ||
        !_validTime(draft.startsAt) ||
        !_validTime(draft.endsAt) ||
        draft.roster.isEmpty ||
        draft.updatedAt.isBefore(draft.createdAt) ||
        (draft.state == AttendanceDraftState.submissionUncertain &&
            (draft.requestId == null || draft.requestId!.isEmpty)) ||
        (draft.state != AttendanceDraftState.submissionUncertain &&
            draft.requestId != null)) {
      throw const FormatException('Invalid attendance draft.');
    }
    final userIds = <String>{};
    final enrolmentIds = <String>{};
    for (final member in draft.roster) {
      if (member.userId.isEmpty ||
          member.enrolmentId.isEmpty ||
          !userIds.add(member.userId) ||
          !enrolmentIds.add(member.enrolmentId) ||
          !draft.statuses.containsKey(member.userId)) {
        throw const FormatException('Invalid attendance draft roster.');
      }
    }
    if (draft.statuses.length != userIds.length ||
        !userIds.containsAll(draft.statuses.keys)) {
      throw const FormatException('Invalid attendance draft statuses.');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}

String _encodeState(AttendanceDraftState state) => switch (state) {
  AttendanceDraftState.saved => 'saved',
  AttendanceDraftState.submissionUncertain => 'submission_uncertain',
  AttendanceDraftState.needsReview => 'needs_review',
};

AttendanceDraftState? _decodeState(String state) => switch (state) {
  'saved' => AttendanceDraftState.saved,
  'submission_uncertain' => AttendanceDraftState.submissionUncertain,
  'needs_review' => AttendanceDraftState.needsReview,
  _ => null,
};

bool _validTime(String value) =>
    RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
