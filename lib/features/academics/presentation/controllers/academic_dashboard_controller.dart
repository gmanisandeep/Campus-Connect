import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/academics/data/supabase_academic_repository.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/academic_repository.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:campus_connect/features/academics/presentation/controllers/attendance_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

typedef AttendanceRequestIdFactory = String Function();

final academicRepositoryProvider = Provider<AcademicRepository>(
  (ref) => SupabaseAcademicRepository(ref.watch(backendGatewayProvider)),
);

final academicTargetDateProvider =
    NotifierProvider<AcademicTargetDateController, DateTime?>(
      AcademicTargetDateController.new,
    );

class AcademicTargetDateController extends Notifier<DateTime?> {
  DateTime? _serverToday;

  @override
  DateTime? build() {
    ref.watch(
      sessionControllerProvider.select(
        (session) => (
          session.status,
          session.userId,
          session.activeGrant?.membershipId,
          session.activeGrant?.selectionKey,
        ),
      ),
    );
    _serverToday = null;
    return null;
  }

  void show(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void rememberServerToday(DateTime date) {
    _serverToday = DateTime(date.year, date.month, date.day);
  }

  void showDraftDate(DateTime date) {
    final serverToday = _serverToday;
    if (serverToday != null && sameAttendanceDate(date, serverToday)) {
      showToday();
      return;
    }
    show(date);
  }

  void showToday() => state = null;
}

final attendanceRequestIdFactoryProvider = Provider<AttendanceRequestIdFactory>(
  (ref) =>
      () => const Uuid().v4(),
);

final academicDashboardControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      AcademicDashboardController,
      AcademicDashboard
    >(AcademicDashboardController.new);

final attendanceSubmissionControllerProvider =
    AsyncNotifierProvider<AttendanceSubmissionController, void>(
      AttendanceSubmissionController.new,
    );

class AcademicDashboardController
    extends AutoDisposeAsyncNotifier<AcademicDashboard> {
  int _loadGeneration = 0;

  @override
  Future<AcademicDashboard> build() {
    _loadGeneration += 1;
    final session = ref.watch(sessionControllerProvider);
    final targetDate = ref.watch(academicTargetDateProvider);
    return _load(session, targetDate);
  }

  Future<void> refresh() async {
    final session = ref.read(sessionControllerProvider);
    final targetDate = ref.read(academicTargetDateProvider);
    final generation = ++_loadGeneration;
    state = const AsyncLoading();
    try {
      final dashboard = await _load(session, targetDate);
      if (_canCommitLoad(session, generation)) {
        state = AsyncData(dashboard);
      }
    } on Object catch (error, stackTrace) {
      if (_canCommitLoad(session, generation)) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  bool applySubmittedDashboard({
    required AcademicDashboard dashboard,
    required String expectedUserId,
    required String expectedSelectionKey,
    required DateTime expectedDate,
    required String expectedTimetableEntryId,
    required String expectedCourseOfferingId,
  }) {
    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    final currentDashboard = state.valueOrNull;
    if (session.userId != expectedUserId ||
        grant?.selectionKey != expectedSelectionKey ||
        currentDashboard == null ||
        currentDashboard.institutionId != grant?.institutionId ||
        currentDashboard.role != grant?.role ||
        !_sameDate(currentDashboard.date, expectedDate) ||
        !_containsClass(
          currentDashboard,
          timetableEntryId: expectedTimetableEntryId,
          courseOfferingId: expectedCourseOfferingId,
        ) ||
        dashboard.institutionId != grant?.institutionId ||
        dashboard.role != grant?.role ||
        !_sameDate(dashboard.date, expectedDate)) {
      return false;
    }
    _loadGeneration += 1;
    state = AsyncData(dashboard);
    return true;
  }

  bool _canCommitLoad(AppSession expectedSession, int generation) {
    final currentSession = ref.read(sessionControllerProvider);
    return generation == _loadGeneration &&
        currentSession.userId == expectedSession.userId &&
        currentSession.activeGrant?.selectionKey ==
            expectedSession.activeGrant?.selectionKey;
  }

  Future<AcademicDashboard> _load(AppSession session, DateTime? targetDate) {
    final grant = _academicGrant(session);
    return ref
        .read(academicRepositoryProvider)
        .loadDashboard(
          institutionId: grant.institutionId,
          role: grant.role,
          targetDate: targetDate,
        );
  }
}

class AttendanceSubmissionController extends AsyncNotifier<void> {
  bool _submissionInFlight = false;

  @override
  FutureOr<void> build() {
    ref.listen(sessionControllerProvider, (_, __) {
      if (!_submissionInFlight) state = const AsyncData(null);
    });
  }

  Future<void> submit({
    required ScheduledClass scheduledClass,
    required Map<String, AttendanceStatus> statuses,
  }) async {
    if (_submissionInFlight) return;
    _submissionInFlight = true;

    final session = ref.read(sessionControllerProvider);
    final grant = session.activeGrant;
    final userId = session.userId;
    final selectionKey = grant?.selectionKey;
    AttendanceDraft? attemptedDraft;
    state = const AsyncLoading();
    try {
      if (!session.isAuthenticated ||
          grant == null ||
          userId == null ||
          !canViewAcademics(grant) ||
          !canSubmitAttendance(grant)) {
        throw const AppFailure(
          kind: FailureKind.authorization,
          message: 'You are not allowed to record attendance.',
        );
      }
      final dashboard = ref
          .read(academicDashboardControllerProvider)
          .valueOrNull;
      if (dashboard == null ||
          dashboard.institutionId != grant.institutionId ||
          dashboard.role != grant.role) {
        throw const AppFailure(
          kind: FailureKind.validation,
          message: 'Refresh academics before submitting attendance.',
        );
      }
      ScheduledClass? currentClass;
      for (final candidate in dashboard.schedule) {
        if (candidate.timetableEntryId == scheduledClass.timetableEntryId &&
            candidate.courseOfferingId == scheduledClass.courseOfferingId) {
          currentClass = candidate;
          break;
        }
      }
      if (currentClass == null) {
        throw const AppFailure(
          kind: FailureKind.validation,
          message: 'Refresh this class before submitting attendance.',
        );
      }
      final sessionDate = dashboard.date;
      if (currentClass.attendanceSubmitted) {
        throw const AppFailure(
          kind: FailureKind.conflict,
          message: 'Attendance has already been submitted for this class.',
        );
      }
      if (currentClass.roster.isEmpty) {
        throw const AppFailure(
          kind: FailureKind.validation,
          message: 'This class has no enrolled students to mark.',
        );
      }
      final marks = <AttendanceMark>[];
      for (final student in currentClass.roster) {
        final status = statuses[student.userId];
        if (status == null) {
          throw const AppFailure(
            kind: FailureKind.validation,
            message: 'Choose a status for every student.',
          );
        }
        marks.add(
          AttendanceMark(studentUserId: student.userId, status: status),
        );
      }
      if (marks.length != statuses.length) {
        throw const AppFailure(
          kind: FailureKind.validation,
          message: 'Refresh the roster before submitting attendance.',
        );
      }

      marks.sort(
        (first, second) => first.studentUserId.compareTo(second.studentUserId),
      );
      attemptedDraft = await ref
          .read(attendanceDraftControllerProvider.notifier)
          .beginSubmission(
            dashboard: dashboard,
            scheduledClass: currentClass,
            statuses: statuses,
            requestIdFactory: ref.read(attendanceRequestIdFactoryProvider),
          );

      final revalidatedSession = ref.read(sessionControllerProvider);
      final revalidatedGrant = revalidatedSession.activeGrant;
      if (!revalidatedSession.isAuthenticated ||
          revalidatedSession.userId != userId ||
          revalidatedGrant == null ||
          revalidatedGrant.membershipId != grant.membershipId ||
          revalidatedGrant.institutionId != grant.institutionId ||
          revalidatedGrant.role != grant.role ||
          revalidatedGrant.selectionKey != selectionKey ||
          !canSubmitAttendance(revalidatedGrant)) {
        throw const AppFailure(
          kind: FailureKind.authorization,
          message: 'Your active account changed before attendance was sent.',
        );
      }
      final latestDashboardState = ref.read(
        academicDashboardControllerProvider,
      );
      final latestDashboard =
          latestDashboardState.isLoading || latestDashboardState.hasError
          ? null
          : latestDashboardState.valueOrNull;
      ScheduledClass? latestClass;
      if (latestDashboard != null) {
        for (final candidate in latestDashboard.schedule) {
          if (candidate.timetableEntryId == currentClass.timetableEntryId &&
              candidate.courseOfferingId == currentClass.courseOfferingId) {
            latestClass = candidate;
            break;
          }
        }
      }
      if (latestDashboard == null ||
          latestDashboard.institutionId != grant.institutionId ||
          latestDashboard.role != grant.role ||
          !_sameDate(latestDashboard.date, sessionDate) ||
          latestClass == null ||
          latestClass.attendanceSubmitted ||
          !attemptedDraft.matchesClass(latestClass, sessionDate) ||
          !attemptedDraft.rosterMatches(latestClass)) {
        throw const AppFailure(
          kind: FailureKind.validation,
          message: 'The class changed before attendance was sent. Refresh it.',
        );
      }

      final refreshed = await ref
          .read(academicRepositoryProvider)
          .submitAttendance(
            institutionId: grant.institutionId,
            courseOfferingId: currentClass.courseOfferingId,
            timetableEntryId: currentClass.timetableEntryId,
            sessionDate: sessionDate,
            marks: List.unmodifiable(marks),
            requestId: attemptedDraft.requestId!,
          );
      await ref
          .read(attendanceDraftControllerProvider.notifier)
          .completeSubmission(attemptedDraft);

      final currentSession = ref.read(sessionControllerProvider);
      if (currentSession.userId == userId &&
          currentSession.activeGrant?.selectionKey == selectionKey) {
        ref
            .read(academicDashboardControllerProvider.notifier)
            .applySubmittedDashboard(
              dashboard: refreshed,
              expectedUserId: userId,
              expectedSelectionKey: selectionKey!,
              expectedDate: sessionDate,
              expectedTimetableEntryId: currentClass.timetableEntryId,
              expectedCourseOfferingId: currentClass.courseOfferingId,
            );
      }
      state = const AsyncData(null);
    } on Object catch (error, stackTrace) {
      if (attemptedDraft != null) {
        try {
          await ref
              .read(attendanceDraftControllerProvider.notifier)
              .markSubmissionFailed(attemptedDraft, error);
        } on Object catch (draftError, draftStackTrace) {
          ref
              .read(appLoggerProvider)
              .error(
                'attendance.draft.failure_transition_not_persisted',
                error: draftError,
                stackTrace: draftStackTrace,
              );
        }
      }
      final currentSession = ref.read(sessionControllerProvider);
      if (currentSession.userId != userId ||
          currentSession.activeGrant?.selectionKey != selectionKey) {
        state = const AsyncData(null);
        return;
      }
      state = AsyncError(error, stackTrace);
    } finally {
      _submissionInFlight = false;
    }
  }
}

AccessGrant _academicGrant(AppSession session) {
  final grant = session.activeGrant;
  if (!session.isAuthenticated || grant == null || !canViewAcademics(grant)) {
    throw const AppFailure(
      kind: FailureKind.authorization,
      message: 'Academic access is not available for this role.',
    );
  }
  return grant;
}

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

bool _containsClass(
  AcademicDashboard dashboard, {
  required String timetableEntryId,
  required String courseOfferingId,
}) {
  for (final scheduledClass in dashboard.schedule) {
    if (scheduledClass.timetableEntryId == timetableEntryId &&
        scheduledClass.courseOfferingId == courseOfferingId) {
      return true;
    }
  }
  return false;
}
