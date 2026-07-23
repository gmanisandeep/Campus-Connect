import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/storage/key_value_store.dart';
import 'package:campus_connect/features/academics/data/drift_attendance_draft_store.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/academic_repository.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:campus_connect/features/academics/presentation/controllers/academic_dashboard_controller.dart';
import 'package:campus_connect/features/academics/presentation/controllers/attendance_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attendance_draft_test_support.dart';

void main() {
  test('loads today from the active grant without a device date', () async {
    final repository = _FakeAcademicRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final dashboard = await container.read(
      academicDashboardControllerProvider.future,
    );

    expect(dashboard.role, AppRole.student);
    expect(repository.loadCalls, hasLength(1));
    expect(
      repository.loadCalls.single.institutionId,
      'development-institution',
    );
    expect(repository.loadCalls.single.role, AppRole.student);
    expect(repository.loadCalls.single.targetDate, isNull);
    expect(dashboard.date, DateTime(2031, 2, 3));
  });

  test(
    'role switch rebuilds the dashboard and faculty submission replaces it',
    () async {
      final repository = _FakeAcademicRepository();
      final container = _container(repository);
      final subscription = container.listen(
        academicDashboardControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);

      await container.read(academicDashboardControllerProvider.future);
      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('development-institution', AppRole.faculty);
      final facultyDashboard = await container.read(
        academicDashboardControllerProvider.future,
      );
      expect(facultyDashboard.role, AppRole.faculty);

      await container
          .read(attendanceSubmissionControllerProvider.notifier)
          .submit(
            scheduledClass: facultyDashboard.schedule.single,
            statuses: const {
              'student-1': AttendanceStatus.present,
              'student-2': AttendanceStatus.absent,
            },
          );

      expect(repository.submitCalls, hasLength(1));
      final call = repository.submitCalls.single;
      expect(call.institutionId, 'development-institution');
      expect(call.sessionDate, DateTime(2031, 2, 3));
      expect(call.requestId, 'request-fixed');
      expect(call.marks.map((mark) => mark.status), [
        AttendanceStatus.present,
        AttendanceStatus.absent,
      ]);
      expect(
        container
            .read(academicDashboardControllerProvider)
            .requireValue
            .schedule
            .single
            .attendanceSubmitted,
        isTrue,
      );
    },
  );

  test('student authority cannot invoke attendance submission', () async {
    final repository = _FakeAcademicRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final dashboard = await container.read(
      academicDashboardControllerProvider.future,
    );

    await container
        .read(attendanceSubmissionControllerProvider.notifier)
        .submit(
          scheduledClass: dashboard.schedule.single,
          statuses: const {
            'student-1': AttendanceStatus.present,
            'student-2': AttendanceStatus.present,
          },
        );

    expect(repository.submitCalls, isEmpty);
    expect(
      container.read(attendanceSubmissionControllerProvider).error,
      isA<AppFailure>().having(
        (failure) => failure.kind,
        'kind',
        FailureKind.authorization,
      ),
    );
  });

  test(
    'durable uncertain draft is written before the attendance RPC',
    () async {
      final repository = _FakeAcademicRepository();
      final store = MemoryAttendanceDraftStore();
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store
        ..upsertStarted = writeStarted
        ..nextUpsertGate = allowWrite;
      final container = _container(repository, draftStore: store);
      final subscription = container.listen(
        academicDashboardControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);

      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('development-institution', AppRole.faculty);
      final dashboard = await container.read(
        academicDashboardControllerProvider.future,
      );
      final submission = container
          .read(attendanceSubmissionControllerProvider.notifier)
          .submit(
            scheduledClass: dashboard.schedule.single,
            statuses: const {
              'student-1': AttendanceStatus.present,
              'student-2': AttendanceStatus.absent,
            },
          );

      await writeStarted.future;
      expect(repository.submitCalls, isEmpty);
      expect(store.drafts, isEmpty);

      allowWrite.complete();
      await submission;

      expect(repository.submitCalls, hasLength(1));
      expect(store.persistedUpserts, hasLength(1));
      expect(
        store.persistedUpserts.single.state,
        AttendanceDraftState.submissionUncertain,
      );
    },
  );

  test('a failed durable preflight prevents the attendance RPC', () async {
    final repository = _FakeAcademicRepository();
    final store = MemoryAttendanceDraftStore()
      ..nextUpsertError = StateError('disk unavailable');
    final container = _container(repository, draftStore: store);
    final subscription = container.listen(
      academicDashboardControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);

    await container
        .read(sessionControllerProvider.notifier)
        .selectAccess('development-institution', AppRole.faculty);
    final dashboard = await container.read(
      academicDashboardControllerProvider.future,
    );
    await container
        .read(attendanceSubmissionControllerProvider.notifier)
        .submit(
          scheduledClass: dashboard.schedule.single,
          statuses: const {
            'student-1': AttendanceStatus.present,
            'student-2': AttendanceStatus.absent,
          },
        );

    expect(repository.submitCalls, isEmpty);
    expect(store.drafts, isEmpty);
    expect(
      container.read(attendanceSubmissionControllerProvider).error,
      isA<StateError>(),
    );
  });

  test('delayed A draft load rejects B submission without an RPC', () async {
    final repository = _FakeAcademicRepository();
    final store = MemoryAttendanceDraftStore();
    final container = _container(
      repository,
      draftStore: store,
      initialSession: _sessionFor('A'),
    );
    final dashboardSubscription = container.listen(
      academicDashboardControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    final draftSubscription = container.listen(
      attendanceDraftControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(dashboardSubscription.close);
    addTearDown(draftSubscription.close);
    addTearDown(container.dispose);
    final dashboardA = await container.read(
      academicDashboardControllerProvider.future,
    );
    await container.read(attendanceDraftControllerProvider.future);
    await container
        .read(attendanceDraftControllerProvider.notifier)
        .save(
          dashboard: dashboardA,
          scheduledClass: dashboardA.schedule.single,
          statuses: const {
            'student-1': AttendanceStatus.present,
            'student-2': AttendanceStatus.absent,
          },
        );
    final loadStarted = Completer<void>();
    final allowLoad = Completer<void>();
    store
      ..loadStarted = loadStarted
      ..nextLoadGate = allowLoad;

    (container.read(sessionControllerProvider.notifier)
            as _MutableSessionController)
        .replace(_sessionFor('B'));
    await loadStarted.future;
    final dashboardB = await container.read(
      academicDashboardControllerProvider.future,
    );
    final submission = container
        .read(attendanceSubmissionControllerProvider.notifier)
        .submit(
          scheduledClass: dashboardB.schedule.single,
          statuses: const {
            'student-1': AttendanceStatus.present,
            'student-2': AttendanceStatus.absent,
          },
        );
    allowLoad.complete();
    await submission;

    expect(repository.submitCalls, isEmpty);
    expect(store.upsertAttempts, hasLength(1));
    expect(store.drafts, isEmpty);
    expect(
      container.read(attendanceSubmissionControllerProvider).error,
      isA<AppFailure>().having(
        (failure) => failure.kind,
        'kind',
        FailureKind.validation,
      ),
    );
  });

  test(
    'session change during durable preflight never reaches the RPC',
    () async {
      final repository = _FakeAcademicRepository();
      final store = MemoryAttendanceDraftStore();
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store
        ..upsertStarted = writeStarted
        ..nextUpsertGate = allowWrite;
      final container = _container(
        repository,
        draftStore: store,
        initialSession: _sessionFor('A'),
      );
      final dashboardSubscription = container.listen(
        academicDashboardControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final draftSubscription = container.listen(
        attendanceDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(dashboardSubscription.close);
      addTearDown(draftSubscription.close);
      addTearDown(container.dispose);
      final dashboardA = await container.read(
        academicDashboardControllerProvider.future,
      );
      await container.read(attendanceDraftControllerProvider.future);

      final submission = container
          .read(attendanceSubmissionControllerProvider.notifier)
          .submit(
            scheduledClass: dashboardA.schedule.single,
            statuses: const {
              'student-1': AttendanceStatus.present,
              'student-2': AttendanceStatus.absent,
            },
          );
      await writeStarted.future;
      (container.read(sessionControllerProvider.notifier)
              as _MutableSessionController)
          .replace(_sessionFor('B'));
      allowWrite.complete();
      await submission;
      await Future<void>.delayed(Duration.zero);
      await container.read(attendanceDraftControllerProvider.future);

      expect(repository.submitCalls, isEmpty);
      expect(store.persistedUpserts, hasLength(1));
      expect(
        store.persistedUpserts.single.state,
        AttendanceDraftState.submissionUncertain,
      );
      expect(
        store.drafts,
        everyElement(
          isA<AttendanceDraft>()
              .having((draft) => draft.userId, 'userId', 'A')
              .having(
                (draft) => draft.state,
                'state',
                AttendanceDraftState.submissionUncertain,
              ),
        ),
      );
      expect(
        container.read(attendanceDraftControllerProvider).requireValue.drafts,
        isEmpty,
      );
    },
  );

  test(
    'dashboard loading after preflight prevents the attendance RPC',
    () async {
      final repository = _FakeAcademicRepository();
      final store = MemoryAttendanceDraftStore();
      final writeStarted = Completer<void>();
      final allowWrite = Completer<void>();
      store
        ..upsertStarted = writeStarted
        ..nextUpsertGate = allowWrite;
      final container = _container(repository, draftStore: store);
      final dashboardSubscription = container.listen(
        academicDashboardControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(dashboardSubscription.close);
      addTearDown(container.dispose);
      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('development-institution', AppRole.faculty);
      final dashboard = await container.read(
        academicDashboardControllerProvider.future,
      );
      await container.read(attendanceDraftControllerProvider.future);

      final submission = container
          .read(attendanceSubmissionControllerProvider.notifier)
          .submit(
            scheduledClass: dashboard.schedule.single,
            statuses: const {
              'student-1': AttendanceStatus.present,
              'student-2': AttendanceStatus.absent,
            },
          );
      await writeStarted.future;
      final delayedDashboard = Completer<AcademicDashboard>();
      repository.nextLoad = delayedDashboard;
      final refresh = container
          .read(academicDashboardControllerProvider.notifier)
          .refresh();
      await _waitUntil(
        () => container.read(academicDashboardControllerProvider).isLoading,
      );
      allowWrite.complete();
      await submission;

      expect(repository.submitCalls, isEmpty);
      expect(store.persistedUpserts, hasLength(2));
      expect(store.drafts.single.state, AttendanceDraftState.saved);
      expect(store.drafts.single.requestId, isNull);
      expect(
        container.read(attendanceSubmissionControllerProvider).error,
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.validation,
        ),
      );

      delayedDashboard.complete(
        _dashboard(role: AppRole.faculty, submitted: false),
      );
      await refresh;
    },
  );

  test(
    'session recomputation cannot duplicate or cross-apply a held RPC',
    () async {
      final repository = _FakeAcademicRepository();
      final heldRpc = Completer<AcademicDashboard>();
      repository.nextSubmit = heldRpc;
      final store = MemoryAttendanceDraftStore();
      final container = _container(
        repository,
        draftStore: store,
        initialSession: _sessionFor('A'),
      );
      final dashboardSubscription = container.listen(
        academicDashboardControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final draftSubscription = container.listen(
        attendanceDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(dashboardSubscription.close);
      addTearDown(draftSubscription.close);
      addTearDown(container.dispose);
      final dashboardA = await container.read(
        academicDashboardControllerProvider.future,
      );
      await container.read(attendanceDraftControllerProvider.future);
      final controller = container.read(
        attendanceSubmissionControllerProvider.notifier,
      );

      final firstSubmission = controller.submit(
        scheduledClass: dashboardA.schedule.single,
        statuses: const {
          'student-1': AttendanceStatus.present,
          'student-2': AttendanceStatus.absent,
        },
      );
      await _waitUntil(() => repository.submitCalls.length == 1);
      expect(
        container.read(attendanceSubmissionControllerProvider).isLoading,
        isTrue,
      );

      (container.read(sessionControllerProvider.notifier)
              as _MutableSessionController)
          .replace(_sessionFor('B'));
      await _waitUntil(() => repository.loadCalls.length >= 2);
      final dashboardB = await container.read(
        academicDashboardControllerProvider.future,
      );
      await controller.submit(
        scheduledClass: dashboardB.schedule.single,
        statuses: const {
          'student-1': AttendanceStatus.present,
          'student-2': AttendanceStatus.absent,
        },
      );

      expect(repository.submitCalls, hasLength(1));
      expect(
        container.read(attendanceSubmissionControllerProvider).isLoading,
        isTrue,
      );

      heldRpc.complete(_dashboard(role: AppRole.faculty, submitted: true));
      await firstSubmission;

      expect(repository.submitCalls, hasLength(1));
      expect(store.persistedUpserts, hasLength(1));
      expect(store.drafts, isEmpty);
      expect(
        container
            .read(academicDashboardControllerProvider)
            .requireValue
            .schedule
            .single
            .attendanceSubmitted,
        isFalse,
      );
      expect(
        container.read(attendanceSubmissionControllerProvider).isLoading,
        isFalse,
      );
    },
  );

  test('a server result cannot cross an authenticated user boundary', () async {
    final repository = _FakeAcademicRepository();
    final container = _container(repository);
    final subscription = container.listen(
      academicDashboardControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    await container.read(academicDashboardControllerProvider.future);

    final applied = container
        .read(academicDashboardControllerProvider.notifier)
        .applySubmittedDashboard(
          dashboard: _dashboard(role: AppRole.student, submitted: true),
          expectedUserId: 'another-user',
          expectedSelectionKey: 'development-institution:student',
          expectedDate: DateTime(2031, 2, 3),
          expectedTimetableEntryId: 'entry-1',
          expectedCourseOfferingId: 'offering-1',
        );

    expect(applied, isFalse);
    expect(
      container
          .read(academicDashboardControllerProvider)
          .requireValue
          .schedule
          .single
          .attendanceSubmitted,
      isFalse,
    );
  });

  test('a late refresh cannot overwrite a newer active role', () async {
    final repository = _FakeAcademicRepository();
    final container = _container(repository);
    final subscription = container.listen(
      academicDashboardControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    await container.read(academicDashboardControllerProvider.future);

    final delayedStudentRefresh = Completer<AcademicDashboard>();
    repository.nextLoad = delayedStudentRefresh;
    final refreshing = container
        .read(academicDashboardControllerProvider.notifier)
        .refresh();
    await _waitUntil(() => repository.loadCalls.length == 2);

    await container
        .read(sessionControllerProvider.notifier)
        .selectAccess('development-institution', AppRole.faculty);
    await _waitUntil(() => repository.loadCalls.last.role == AppRole.faculty);
    expect(
      (await container.read(academicDashboardControllerProvider.future)).role,
      AppRole.faculty,
    );

    delayedStudentRefresh.complete(
      _dashboard(role: AppRole.student, submitted: true),
    );
    await refreshing;

    expect(
      container.read(academicDashboardControllerProvider).requireValue.role,
      AppRole.faculty,
    );
  });

  test('uncertain retries reuse the key and reject changed marks', () async {
    final repository = _FakeAcademicRepository()
      ..submitError = const AppFailure(
        kind: FailureKind.connectivity,
        message: 'Connection interrupted.',
      );
    var requestCount = 0;
    final store = MemoryAttendanceDraftStore();
    final container = _container(
      repository,
      draftStore: store,
      requestIdFactory: () => 'request-${++requestCount}',
    );
    addTearDown(container.dispose);
    await container
        .read(sessionControllerProvider.notifier)
        .selectAccess('development-institution', AppRole.faculty);
    final dashboard = await container.read(
      academicDashboardControllerProvider.future,
    );
    final controller = container.read(
      attendanceSubmissionControllerProvider.notifier,
    );
    const firstMarks = {
      'student-1': AttendanceStatus.present,
      'student-2': AttendanceStatus.absent,
    };

    await controller.submit(
      scheduledClass: dashboard.schedule.single,
      statuses: firstMarks,
    );
    await controller.submit(
      scheduledClass: dashboard.schedule.single,
      statuses: firstMarks,
    );
    await controller.submit(
      scheduledClass: dashboard.schedule.single,
      statuses: const {
        'student-1': AttendanceStatus.present,
        'student-2': AttendanceStatus.late,
      },
    );

    expect(repository.submitCalls.map((call) => call.requestId), [
      'request-1',
      'request-1',
    ]);
    expect(requestCount, 1);
    expect(
      container.read(attendanceSubmissionControllerProvider).error,
      isA<AppFailure>().having(
        (failure) => failure.kind,
        'kind',
        FailureKind.conflict,
      ),
    );
    expect(store.drafts.single.state, AttendanceDraftState.submissionUncertain);
  });
}

ProviderContainer _container(
  AcademicRepository repository, {
  MemoryAttendanceDraftStore? draftStore,
  AttendanceRequestIdFactory? requestIdFactory,
  AppSession? initialSession,
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig(
        environment: AppEnvironment.test,
        supabaseUrl: '',
        supabaseAnonKey: '',
        enableDesignSystemGallery: false,
        enableDemoSession: initialSession == null,
      ),
    ),
    if (initialSession != null)
      sessionControllerProvider.overrideWith(
        () => _MutableSessionController(initialSession),
      ),
    academicRepositoryProvider.overrideWithValue(repository),
    attendanceDraftStoreProvider.overrideWithValue(
      draftStore ?? MemoryAttendanceDraftStore(),
    ),
    attendanceRequestIdFactoryProvider.overrideWithValue(
      requestIdFactory ?? () => 'request-fixed',
    ),
    keyValueStoreProvider.overrideWithValue(_MemoryKeyValueStore()),
  ],
);

class _FakeAcademicRepository implements AcademicRepository {
  final List<_LoadCall> loadCalls = [];
  final List<_SubmitCall> submitCalls = [];
  Completer<AcademicDashboard>? nextLoad;
  Completer<AcademicDashboard>? nextSubmit;
  Object? submitError;

  @override
  Future<AcademicDashboard> loadDashboard({
    required String institutionId,
    required AppRole role,
    required DateTime? targetDate,
  }) async {
    loadCalls.add(_LoadCall(institutionId, role, targetDate));
    final delayed = nextLoad;
    nextLoad = null;
    if (delayed != null) return delayed.future;
    return _dashboard(role: role, submitted: false);
  }

  @override
  Future<AcademicDashboard> submitAttendance({
    required String institutionId,
    required String courseOfferingId,
    required String timetableEntryId,
    required DateTime sessionDate,
    required List<AttendanceMark> marks,
    required String requestId,
  }) async {
    submitCalls.add(
      _SubmitCall(
        institutionId: institutionId,
        sessionDate: sessionDate,
        marks: marks,
        requestId: requestId,
      ),
    );
    final delayed = nextSubmit;
    nextSubmit = null;
    if (delayed != null) return delayed.future;
    final error = submitError;
    if (error != null) throw error;
    return _dashboard(role: AppRole.faculty, submitted: true);
  }
}

class _LoadCall {
  const _LoadCall(this.institutionId, this.role, this.targetDate);

  final String institutionId;
  final AppRole role;
  final DateTime? targetDate;
}

class _SubmitCall {
  const _SubmitCall({
    required this.institutionId,
    required this.sessionDate,
    required this.marks,
    required this.requestId,
  });

  final String institutionId;
  final DateTime sessionDate;
  final List<AttendanceMark> marks;
  final String requestId;
}

AcademicDashboard _dashboard({
  required AppRole role,
  required bool submitted,
}) => AcademicDashboard(
  institutionId: 'development-institution',
  role: role,
  date: DateTime(2031, 2, 3),
  schedule: [
    ScheduledClass(
      timetableEntryId: 'entry-1',
      courseOfferingId: 'offering-1',
      subjectCode: 'CS701',
      subjectName: 'Distributed Systems',
      sectionName: 'CSE A',
      startsAt: '09:00',
      endsAt: '10:00',
      room: 'A-101',
      attendanceSessionId: submitted ? 'session-1' : null,
      attendanceSubmitted: submitted,
      roster: [
        RosterStudent(
          enrolmentId: 'enrolment-1',
          userId: 'student-1',
          displayName: 'Ada Student',
          status: submitted ? AttendanceStatus.present : null,
        ),
        RosterStudent(
          enrolmentId: 'enrolment-2',
          userId: 'student-2',
          displayName: 'Lin Student',
          status: submitted ? AttendanceStatus.absent : null,
        ),
      ],
    ),
  ],
  attendanceSummary: const [],
);

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

AppSession _sessionFor(String userId) {
  const grant = AccessGrant(
    membershipId: 'development-membership',
    institutionId: 'development-institution',
    institutionName: 'Development institution',
    role: AppRole.faculty,
    permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
  );
  return AppSession.authenticated(
    identity: IdentityContext(
      userId: userId,
      profileCompleted: true,
      memberships: const [
        MembershipSummary(
          id: 'development-membership',
          institutionId: 'development-institution',
          institutionName: 'Development institution',
          institutionActive: true,
          status: MembershipStatus.active,
          grants: [grant],
        ),
      ],
    ),
    activeGrant: grant,
  );
}

class _MutableSessionController extends SessionController {
  _MutableSessionController(this._initialSession);

  final AppSession _initialSession;

  @override
  AppSession build() => _initialSession;

  void replace(AppSession session) => state = session;
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    if (condition()) return;
  }
  fail('Condition did not become true.');
}
