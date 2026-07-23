import 'dart:async';

import 'package:campus_connect/features/academics/domain/attendance_draft.dart';

/// Deterministic in-memory draft storage shared by controller tests.
///
/// [nextUpsertGate] and [nextUpsertError] make the durable-write boundary
/// observable without weakening the production abstraction.
class MemoryAttendanceDraftStore implements AttendanceDraftStore {
  MemoryAttendanceDraftStore({
    Iterable<AttendanceDraft> initialDrafts = const [],
  }) : _drafts = {for (final draft in initialDrafts) draft.storageKey: draft};

  final Map<String, AttendanceDraft> _drafts;
  final List<AttendanceDraft> upsertAttempts = [];
  final List<AttendanceDraft> persistedUpserts = [];
  final List<String> deletedKeys = [];
  int deleteAllCalls = 0;
  int deleteForUserCalls = 0;

  Completer<void>? nextUpsertGate;
  Object? nextUpsertError;
  Completer<void>? upsertStarted;
  Completer<void>? nextLoadGate;
  Completer<void>? loadStarted;

  List<AttendanceDraft> get drafts => List.unmodifiable(_drafts.values);

  AttendanceDraft? operator [](String storageKey) => _drafts[storageKey];

  @override
  Future<List<AttendanceDraft>> loadAll() async {
    final started = loadStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = nextLoadGate;
    nextLoadGate = null;
    if (gate != null) await gate.future;
    return drafts;
  }

  @override
  Future<void> upsert(AttendanceDraft draft) async {
    upsertAttempts.add(draft);
    final started = upsertStarted;
    if (started != null && !started.isCompleted) started.complete();

    final gate = nextUpsertGate;
    nextUpsertGate = null;
    if (gate != null) await gate.future;

    final error = nextUpsertError;
    nextUpsertError = null;
    if (error != null) throw error;

    _drafts[draft.storageKey] = draft;
    persistedUpserts.add(draft);
  }

  @override
  Future<void> delete(String storageKey) async {
    deletedKeys.add(storageKey);
    _drafts.remove(storageKey);
  }

  @override
  Future<void> deleteForUser(String userId) async {
    deleteForUserCalls += 1;
    _drafts.removeWhere((_, draft) => draft.userId == userId);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls += 1;
    _drafts.clear();
  }
}
