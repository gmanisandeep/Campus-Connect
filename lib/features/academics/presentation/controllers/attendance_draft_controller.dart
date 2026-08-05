import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/academics/data/drift_attendance_draft_store.dart'
    if (dart.library.js_interop) 'package:campus_connect/features/academics/data/web_attendance_draft_store.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AttendanceDraftClock = DateTime Function();

final attendanceDraftClockProvider = Provider<AttendanceDraftClock>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final attendanceDraftControllerProvider =
    AsyncNotifierProvider<AttendanceDraftController, AttendanceDraftBook>(
      AttendanceDraftController.new,
    );

class AttendanceDraftController extends AsyncNotifier<AttendanceDraftBook> {
  static const editableDraftRetention = Duration(days: 30);

  Future<void> _operationTail = Future<void>.value();
  AttendanceDraftBook _book = AttendanceDraftBook.empty();
  String? _loadedAuthorityKey;
  bool _hasStartedBuild = false;

  @override
  Future<AttendanceDraftBook> build() {
    final isReload = _hasStartedBuild;
    _hasStartedBuild = true;
    final session = ref.watch(sessionControllerProvider);
    final store = ref.watch(attendanceDraftStoreProvider);
    final nextAuthorityKey = _visibleAuthorityKey(session);
    if (nextAuthorityKey == null || nextAuthorityKey != _loadedAuthorityKey) {
      // Never retain the previous Faculty scope in memory while an identity,
      // role, or authorization transition is waiting on encrypted storage.
      _clearVisibleBook();
      if (isReload) state = AsyncData(_book);
    }
    return _enqueue(() => _loadForSession(session, store));
  }

  Future<void> save({
    required AcademicDashboard dashboard,
    required ScheduledClass scheduledClass,
    required Map<String, AttendanceStatus> statuses,
  }) => _enqueue(() async {
    final context = _validatedContext(
      dashboard: dashboard,
      scheduledClass: scheduledClass,
      statuses: statuses,
    );
    final existing = _book.forClass(context.scheduledClass, dashboard.date);
    if (existing != null && !existing.isEditable) {
      throw const AppFailure(
        kind: FailureKind.conflict,
        message: 'This draft is frozen until its submission is resolved.',
      );
    }
    if (existing != null &&
        (!existing.matchesClass(context.scheduledClass, dashboard.date) ||
            !existing.rosterMatches(context.scheduledClass))) {
      await _persistNeedsReview(existing);
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'The class or roster changed. Review it before continuing.',
      );
    }

    final now = _now();
    final draft = existing == null
        ? _newDraft(
            context: context,
            sessionDate: dashboard.date,
            statuses: statuses,
            state: AttendanceDraftState.saved,
            requestId: null,
            now: now,
          )
        : existing.copyWith(
            statuses: statuses,
            state: AttendanceDraftState.saved,
            clearRequestId: true,
            updatedAt: now,
          );
    await ref.read(attendanceDraftStoreProvider).upsert(draft);
    _commit(_book.put(draft));
  });

  Future<AttendanceDraft> beginSubmission({
    required AcademicDashboard dashboard,
    required ScheduledClass scheduledClass,
    required Map<String, AttendanceStatus> statuses,
    required String Function() requestIdFactory,
  }) => _enqueue(() async {
    final context = _validatedContext(
      dashboard: dashboard,
      scheduledClass: scheduledClass,
      statuses: statuses,
    );
    final existing = _book.forClass(context.scheduledClass, dashboard.date);
    if (existing != null &&
        (!existing.matchesClass(context.scheduledClass, dashboard.date) ||
            !existing.rosterMatches(context.scheduledClass))) {
      await _persistNeedsReview(existing);
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'The class or roster changed. Review it before continuing.',
      );
    }
    if (existing?.state == AttendanceDraftState.needsReview) {
      throw const AppFailure(
        kind: FailureKind.conflict,
        message: 'Review or discard this draft before submitting.',
      );
    }
    if (existing?.state == AttendanceDraftState.submissionUncertain) {
      if (!existing!.hasStatuses(statuses)) {
        throw const AppFailure(
          kind: FailureKind.conflict,
          message: 'Only the exact pending submission can be retried.',
        );
      }
      return existing;
    }

    final now = _now();
    final requestId = requestIdFactory();
    if (requestId.trim().isEmpty) {
      throw const AppFailure(
        kind: FailureKind.unexpected,
        message: 'Unable to prepare a safe attendance request.',
      );
    }
    final draft = existing == null
        ? _newDraft(
            context: context,
            sessionDate: dashboard.date,
            statuses: statuses,
            state: AttendanceDraftState.submissionUncertain,
            requestId: requestId,
            now: now,
          )
        : existing.copyWith(
            statuses: statuses,
            state: AttendanceDraftState.submissionUncertain,
            requestId: requestId,
            updatedAt: now,
          );

    // This durable write must finish before the RPC starts. A process death
    // after this point can only leave an exact, idempotent retry payload.
    await ref.read(attendanceDraftStoreProvider).upsert(draft);
    _commit(_book.put(draft));
    return draft;
  });

  Future<void> markSubmissionFailed(
    AttendanceDraft attemptedDraft,
    Object error,
  ) => _enqueue(() async {
    if (!_hasCurrentAuthorityFor(attemptedDraft)) return;
    final current = _book.drafts[attemptedDraft.storageKey];
    if (current == null ||
        current.state != AttendanceDraftState.submissionUncertain ||
        current.requestId != attemptedDraft.requestId) {
      return;
    }

    final nextState = _stateAfterFailure(error);
    if (nextState == AttendanceDraftState.submissionUncertain) return;
    final updated = current.copyWith(
      state: nextState,
      clearRequestId: true,
      updatedAt: _now(),
    );
    await ref.read(attendanceDraftStoreProvider).upsert(updated);
    _commit(_book.put(updated));
  });

  Future<void> completeSubmission(AttendanceDraft confirmedDraft) =>
      _enqueue(() async {
        if (!_hasCurrentAuthorityFor(confirmedDraft)) return;
        final current = _book.drafts[confirmedDraft.storageKey];
        if (current == null ||
            current.state != AttendanceDraftState.submissionUncertain ||
            current.requestId != confirmedDraft.requestId) {
          return;
        }
        await ref
            .read(attendanceDraftStoreProvider)
            .delete(confirmedDraft.storageKey);
        _commit(_book.remove(confirmedDraft.storageKey));
      });

  Future<void> discard(AttendanceDraft draft) => _enqueue(() async {
    if (!_hasCurrentAuthorityFor(draft)) {
      throw const AppFailure(
        kind: FailureKind.authorization,
        message: 'This draft is not available in the active account.',
      );
    }
    await ref.read(attendanceDraftStoreProvider).delete(draft.storageKey);
    _commit(_book.remove(draft.storageKey));
  });

  Future<void> reconcile(
    AcademicDashboard dashboard, {
    bool historical = false,
  }) => _enqueue(() async {
    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    final userId = session.userId;
    if (!session.isAuthenticated ||
        userId == null ||
        grant == null ||
        grant.role != AppRole.faculty ||
        !canSubmitAttendance(grant) ||
        dashboard.institutionId != grant.institutionId ||
        dashboard.role != AppRole.faculty ||
        _loadedAuthorityKey != _authorityKey(userId, grant)) {
      return;
    }

    var nextBook = _book;
    var changed = false;
    for (final draft in _book.drafts.values.toList(growable: false)) {
      if (!draft.matchesAuthority(
        expectedUserId: userId,
        expectedMembershipId: grant.membershipId,
        expectedInstitutionId: grant.institutionId,
        expectedSelectionKey: grant.selectionKey,
      )) {
        continue;
      }

      if (!historical &&
          draft.state == AttendanceDraftState.saved &&
          _calendarDayDifference(draft.sessionDate, dashboard.date) >
              editableDraftRetention.inDays) {
        await ref.read(attendanceDraftStoreProvider).delete(draft.storageKey);
        nextBook = nextBook.remove(draft.storageKey);
        changed = true;
        continue;
      }
      if (!sameAttendanceDate(draft.sessionDate, dashboard.date)) continue;

      final scheduledClass = _findClass(
        dashboard,
        courseOfferingId: draft.courseOfferingId,
        timetableEntryId: draft.timetableEntryId,
      );
      if (scheduledClass != null &&
          scheduledClass.attendanceSubmitted &&
          _serverConfirms(draft, scheduledClass)) {
        await ref.read(attendanceDraftStoreProvider).delete(draft.storageKey);
        nextBook = nextBook.remove(draft.storageKey);
        changed = true;
        continue;
      }

      if (historical) {
        if (draft.state != AttendanceDraftState.needsReview) {
          final reviewed = draft.copyWith(
            state: AttendanceDraftState.needsReview,
            clearRequestId: true,
            updatedAt: _now(),
          );
          await ref.read(attendanceDraftStoreProvider).upsert(reviewed);
          nextBook = nextBook.put(reviewed);
          changed = true;
        }
        continue;
      }

      if (scheduledClass == null ||
          !draft.matchesClass(scheduledClass, dashboard.date) ||
          !draft.rosterMatches(scheduledClass) ||
          scheduledClass.attendanceSubmitted) {
        if (draft.state != AttendanceDraftState.needsReview) {
          final reviewed = draft.copyWith(
            state: AttendanceDraftState.needsReview,
            clearRequestId: true,
            updatedAt: _now(),
          );
          await ref.read(attendanceDraftStoreProvider).upsert(reviewed);
          nextBook = nextBook.put(reviewed);
          changed = true;
        }
      }
    }
    if (changed) _commit(nextBook);
  });

  Future<AttendanceDraftBook> _loadForSession(
    AppSession session,
    AttendanceDraftStore store,
  ) async {
    if (session.status == SessionStatus.signedOut ||
        session.status == SessionStatus.passwordRecovery) {
      _clearVisibleBook();
      await store.deleteAll();
      return _book;
    }

    final userId = session.userId;
    if (userId == null) {
      // Unknown and identity-less blocked states cannot safely attribute the
      // encrypted rows. Keep them hidden until identity becomes authoritative.
      _clearVisibleBook();
      return _book;
    }

    final allDrafts = await store.loadAll();
    if (!identical(ref.read(sessionControllerProvider), session)) {
      // A newer identity/authorization snapshot superseded this load. Never
      // let stale revocation logic delete rows owned by the newer snapshot.
      _clearVisibleBook();
      return _book;
    }
    if (allDrafts.any((draft) => draft.userId != userId)) {
      // A different identity must never inherit or briefly expose encrypted
      // drafts, including during onboarding, selection, and blocked states.
      _clearVisibleBook();
      await store.deleteAll();
      return _book;
    }

    final retainedDrafts = <AttendanceDraft>[];
    var purgedRevokedScope = false;
    for (final draft in allDrafts) {
      final remainsAuthorized = session.availableGrants.any(
        (candidate) =>
            candidate.role == AppRole.faculty &&
            canSubmitAttendance(candidate) &&
            draft.matchesAuthority(
              expectedUserId: userId,
              expectedMembershipId: candidate.membershipId,
              expectedInstitutionId: candidate.institutionId,
              expectedSelectionKey: candidate.selectionKey,
            ),
      );
      if (!remainsAuthorized) {
        await store.delete(draft.storageKey);
        purgedRevokedScope = true;
      } else {
        retainedDrafts.add(draft);
      }
    }
    if (purgedRevokedScope) {
      ref
          .read(appLoggerProvider)
          .warning('attendance.draft.revoked_scope_purged');
    }

    if (!session.isAuthenticated) {
      // Identity-bearing non-authenticated states still perform revocation
      // cleanup above, but no draft is visible until a Faculty grant is active.
      _clearVisibleBook();
      return _book;
    }

    final grant = session.activeGrant;
    if (grant == null ||
        grant.role != AppRole.faculty ||
        !canSubmitAttendance(grant)) {
      _clearVisibleBook();
      return _book;
    }
    if (!identical(ref.read(sessionControllerProvider), session)) {
      // A newer session snapshot invalidated this load while storage was
      // pending. Its queued rebuild owns the next visible book.
      _clearVisibleBook();
      return _book;
    }
    final visible = <String, AttendanceDraft>{};
    for (final draft in retainedDrafts) {
      if (draft.matchesAuthority(
        expectedUserId: userId,
        expectedMembershipId: grant.membershipId,
        expectedInstitutionId: grant.institutionId,
        expectedSelectionKey: grant.selectionKey,
      )) {
        visible[draft.storageKey] = draft;
      }
    }
    _book = AttendanceDraftBook(visible);
    _loadedAuthorityKey = _authorityKey(userId, grant);
    return _book;
  }

  _ValidatedDraftContext _validatedContext({
    required AcademicDashboard dashboard,
    required ScheduledClass scheduledClass,
    required Map<String, AttendanceStatus> statuses,
  }) {
    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    final userId = session.userId;
    if (!session.isAuthenticated ||
        userId == null ||
        grant == null ||
        grant.role != AppRole.faculty ||
        !canSubmitAttendance(grant)) {
      throw const AppFailure(
        kind: FailureKind.authorization,
        message: 'You are not allowed to record attendance.',
      );
    }
    if (dashboard.institutionId != grant.institutionId ||
        dashboard.role != AppRole.faculty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'Refresh academics before changing attendance.',
      );
    }
    if (_loadedAuthorityKey != _authorityKey(userId, grant)) {
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'Wait for secure drafts to finish loading, then try again.',
      );
    }
    final currentClass = _findClass(
      dashboard,
      courseOfferingId: scheduledClass.courseOfferingId,
      timetableEntryId: scheduledClass.timetableEntryId,
    );
    if (currentClass == null ||
        currentClass.attendanceSubmitted ||
        currentClass.roster.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'Refresh this class before changing attendance.',
      );
    }
    _validateStatuses(currentClass, statuses);
    return _ValidatedDraftContext(
      userId: userId,
      grant: grant,
      scheduledClass: currentClass,
    );
  }

  AttendanceDraft _newDraft({
    required _ValidatedDraftContext context,
    required DateTime sessionDate,
    required Map<String, AttendanceStatus> statuses,
    required AttendanceDraftState state,
    required String? requestId,
    required DateTime now,
  }) => AttendanceDraft(
    userId: context.userId,
    membershipId: context.grant.membershipId,
    institutionId: context.grant.institutionId,
    selectionKey: context.grant.selectionKey,
    courseOfferingId: context.scheduledClass.courseOfferingId,
    timetableEntryId: context.scheduledClass.timetableEntryId,
    subjectCode: context.scheduledClass.subjectCode,
    subjectName: context.scheduledClass.subjectName,
    startsAt: context.scheduledClass.startsAt,
    endsAt: context.scheduledClass.endsAt,
    sessionDate: sessionDate,
    roster: [
      for (final student in context.scheduledClass.roster)
        AttendanceDraftRosterMember(
          enrolmentId: student.enrolmentId,
          userId: student.userId,
        ),
    ],
    statuses: statuses,
    state: state,
    requestId: requestId,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> _persistNeedsReview(AttendanceDraft draft) async {
    final reviewed = draft.copyWith(
      state: AttendanceDraftState.needsReview,
      clearRequestId: true,
      updatedAt: _now(),
    );
    await ref.read(attendanceDraftStoreProvider).upsert(reviewed);
    _commit(_book.put(reviewed));
  }

  bool _hasCurrentAuthorityFor(AttendanceDraft draft) {
    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    return session.isAuthenticated &&
        session.userId != null &&
        grant != null &&
        grant.role == AppRole.faculty &&
        canSubmitAttendance(grant) &&
        _loadedAuthorityKey == _authorityKey(session.userId!, grant) &&
        draft.matchesAuthority(
          expectedUserId: session.userId!,
          expectedMembershipId: grant.membershipId,
          expectedInstitutionId: grant.institutionId,
          expectedSelectionKey: grant.selectionKey,
        );
  }

  DateTime _now() => ref.read(attendanceDraftClockProvider)().toUtc();

  void _commit(AttendanceDraftBook book) {
    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    final userId = session.userId;
    final authorityKey = _visibleAuthorityKey(session);
    if (userId == null ||
        grant == null ||
        authorityKey == null ||
        authorityKey != _loadedAuthorityKey) {
      _clearVisibleBook();
      state = AsyncData(_book);
      return;
    }

    final visible = <String, AttendanceDraft>{};
    for (final draft in book.drafts.values) {
      if (draft.matchesAuthority(
        expectedUserId: userId,
        expectedMembershipId: grant.membershipId,
        expectedInstitutionId: grant.institutionId,
        expectedSelectionKey: grant.selectionKey,
      )) {
        visible[draft.storageKey] = draft;
      }
    }
    _book = AttendanceDraftBook(visible);
    state = AsyncData(_book);
  }

  void _clearVisibleBook() {
    _book = AttendanceDraftBook.empty();
    _loadedAuthorityKey = null;
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

String _authorityKey(String userId, AccessGrant grant) =>
    '$userId|${grant.membershipId}|${grant.selectionKey}';

String? _visibleAuthorityKey(AppSession session) {
  final userId = session.userId;
  final grant = session.activeGrant;
  if (!session.isAuthenticated ||
      userId == null ||
      grant == null ||
      grant.role != AppRole.faculty ||
      !canSubmitAttendance(grant)) {
    return null;
  }
  return _authorityKey(userId, grant);
}

class _ValidatedDraftContext {
  const _ValidatedDraftContext({
    required this.userId,
    required this.grant,
    required this.scheduledClass,
  });

  final String userId;
  final AccessGrant grant;
  final ScheduledClass scheduledClass;
}

void _validateStatuses(
  ScheduledClass scheduledClass,
  Map<String, AttendanceStatus> statuses,
) {
  if (statuses.length != scheduledClass.roster.length) {
    throw const AppFailure(
      kind: FailureKind.validation,
      message: 'Choose a status for every current student.',
    );
  }
  for (final student in scheduledClass.roster) {
    if (!statuses.containsKey(student.userId)) {
      throw const AppFailure(
        kind: FailureKind.validation,
        message: 'Choose a status for every current student.',
      );
    }
  }
}

ScheduledClass? _findClass(
  AcademicDashboard dashboard, {
  required String courseOfferingId,
  required String timetableEntryId,
}) {
  for (final scheduledClass in dashboard.schedule) {
    if (scheduledClass.courseOfferingId == courseOfferingId &&
        scheduledClass.timetableEntryId == timetableEntryId) {
      return scheduledClass;
    }
  }
  return null;
}

bool _serverConfirms(AttendanceDraft draft, ScheduledClass scheduledClass) {
  if (!scheduledClass.attendanceSubmitted ||
      scheduledClass.attendanceSessionId == null ||
      scheduledClass.attendanceSessionId!.isEmpty ||
      !draft.matchesClass(scheduledClass, draft.sessionDate) ||
      !draft.rosterMatches(scheduledClass)) {
    return false;
  }
  for (final student in scheduledClass.roster) {
    if (student.status != draft.statuses[student.userId]) return false;
  }
  return true;
}

AttendanceDraftState _stateAfterFailure(Object error) {
  if (error is! AppFailure) return AttendanceDraftState.submissionUncertain;
  return switch (error.kind) {
    FailureKind.validation => AttendanceDraftState.saved,
    FailureKind.authentication ||
    FailureKind.authorization ||
    FailureKind.notFound ||
    FailureKind.conflict => AttendanceDraftState.needsReview,
    FailureKind.connectivity ||
    FailureKind.timeout ||
    FailureKind.server ||
    FailureKind.unexpected => AttendanceDraftState.submissionUncertain,
  };
}

int _calendarDayDifference(DateTime earlier, DateTime later) {
  final earlierDay = DateTime.utc(earlier.year, earlier.month, earlier.day);
  final laterDay = DateTime.utc(later.year, later.month, later.day);
  return laterDay.difference(earlierDay).inDays;
}
