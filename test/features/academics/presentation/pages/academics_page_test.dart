import 'dart:async';

import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/storage/key_value_store.dart';
import 'package:campus_connect/features/academics/data/drift_attendance_draft_store.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/academic_repository.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:campus_connect/features/academics/presentation/controllers/academic_dashboard_controller.dart';
import 'package:campus_connect/features/academics/presentation/pages/academics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student sees today timetable and attendance summary', (
    tester,
  ) async {
    final repository = _PageAcademicRepository();
    final store = _MemoryAttendanceDraftStore();
    final connectivity = _FakeConnectivityService(NetworkStatus.online);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);

    await _pumpPage(tester, container);

    expect(find.text("Today's timetable"), findsOneWidget);
    expect(find.text('CS701 · Distributed Systems'), findsOneWidget);
    expect(find.text('Attendance summary'), findsOneWidget);
    expect(find.text('85.0%'), findsOneWidget);
    expect(find.textContaining('17 attended of 20'), findsOneWidget);
  });

  testWidgets('faculty explicitly saves a draft without submitting', (
    tester,
  ) async {
    final store = _MemoryAttendanceDraftStore();
    final firstRepository = _PageAcademicRepository();
    final firstConnectivity = _FakeConnectivityService(NetworkStatus.online);
    final firstContainer = _container(
      firstRepository,
      draftStore: store,
      connectivity: firstConnectivity,
    );
    addTearDown(firstContainer.dispose);
    addTearDown(firstConnectivity.close);
    await _selectFaculty(firstContainer);
    await _pumpPage(tester, firstContainer);
    await _expandFacultyClass(tester);

    await _chooseStatus(tester, studentUserId: 'student-1', label: 'Absent');
    expect(store.drafts, isEmpty);

    final save = find.byKey(const Key('save-attendance-draft-entry-1'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(firstRepository.submitCount, 0);
    expect(store.drafts, hasLength(1));
    expect(store.drafts.single.statuses['student-1'], AttendanceStatus.absent);
    expect(find.textContaining('saved on this device'), findsOneWidget);
  });

  testWidgets('faculty restores marks from an on-device draft', (tester) async {
    final repository = _PageAcademicRepository();
    final store = _MemoryAttendanceDraftStore([
      _draft(state: AttendanceDraftState.saved),
    ]);
    final connectivity = _FakeConnectivityService(NetworkStatus.online);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
    await _selectFaculty(container);
    await _pumpPage(tester, container);
    await _expandFacultyClass(tester);

    final restored = tester.widget<DropdownButton<AttendanceStatus>>(
      find.byKey(const Key('attendance-status-student-1')),
    );
    expect(restored.value, AttendanceStatus.absent);
    expect(find.textContaining('saved on this device'), findsOneWidget);
    expect(repository.submitCount, 0);
  });

  testWidgets(
    'offline disables submission, allows save, and reconnect never submits',
    (tester) async {
      final repository = _PageAcademicRepository();
      final store = _MemoryAttendanceDraftStore();
      final connectivity = _FakeConnectivityService(NetworkStatus.offline);
      final container = _container(
        repository,
        draftStore: store,
        connectivity: connectivity,
      );
      addTearDown(container.dispose);
      addTearDown(connectivity.close);
      await _selectFaculty(container);
      await _pumpPage(tester, container);
      await _expandFacultyClass(tester);

      final submit = find.byKey(const Key('submit-attendance-entry-1'));
      final save = find.byKey(const Key('save-attendance-draft-entry-1'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(save).onPressed, isNotNull);
      expect(find.text('Submit when online'), findsOneWidget);

      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(store.drafts, hasLength(1));
      expect(repository.submitCount, 0);

      connectivity.emit(NetworkStatus.online);
      await tester.pumpAndSettle();

      expect(repository.submitCount, 0);
      expect(find.text('Submit attendance'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      expect(store.drafts.single.state, AttendanceDraftState.saved);
    },
  );

  testWidgets(
    'uncertain submission freezes marks and offers exact retry only',
    (tester) async {
      final repository = _PageAcademicRepository();
      final store = _MemoryAttendanceDraftStore([
        _draft(state: AttendanceDraftState.submissionUncertain),
      ]);
      final connectivity = _FakeConnectivityService(NetworkStatus.online);
      final container = _container(
        repository,
        draftStore: store,
        connectivity: connectivity,
      );
      addTearDown(container.dispose);
      addTearDown(connectivity.close);
      await _selectFaculty(container);
      await _pumpPage(tester, container);
      await _expandFacultyClass(tester);

      expect(find.textContaining('Pending confirmation'), findsOneWidget);
      expect(find.text('Retry exact submission'), findsOneWidget);
      expect(
        find.textContaining('Only this exact frozen submission can be retried'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<DropdownButton<AttendanceStatus>>(
              find.byKey(const Key('attendance-status-student-1')),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButton<AttendanceStatus>>(
              find.byKey(const Key('attendance-status-student-2')),
            )
            .onChanged,
        isNull,
      );
      expect(
        find.byKey(const Key('save-attendance-draft-entry-1')),
        findsNothing,
      );
      expect(repository.submitCount, 0);
    },
  );

  testWidgets(
    'past and changed-class drafts stay recoverable without student names',
    (tester) async {
      final pastDraft = _draft(
        state: AttendanceDraftState.saved,
        sessionDate: DateTime(2026, 7, 19),
      );
      final changedClassDraft = _draft(
        state: AttendanceDraftState.saved,
        courseOfferingId: 'offering-legacy',
        timetableEntryId: 'entry-legacy',
        subjectCode: 'CS699',
        subjectName: 'Legacy Seminar',
        startsAt: '11:00',
        endsAt: '12:00',
      );
      final repository = _PageAcademicRepository();
      final store = _MemoryAttendanceDraftStore([pastDraft, changedClassDraft]);
      final connectivity = _FakeConnectivityService(NetworkStatus.online);
      final container = _container(
        repository,
        draftStore: store,
        connectivity: connectivity,
      );
      addTearDown(container.dispose);
      addTearDown(connectivity.close);
      await _selectFaculty(container);

      await _pumpPage(tester, container);

      expect(find.text('Saved on this device'), findsOneWidget);
      for (final draft in [pastDraft, changedClassDraft]) {
        final recoveryCard = find.byKey(
          Key('attendance-draft-recovery-${draft.storageKey}'),
        );
        expect(recoveryCard, findsOneWidget);
        expect(
          find.descendant(of: recoveryCard, matching: find.text('Ada Student')),
          findsNothing,
        );
        expect(
          find.descendant(of: recoveryCard, matching: find.text('Lin Student')),
          findsNothing,
        );
      }
      expect(find.textContaining('2 students'), findsNWidgets(2));
      expect(repository.submitCount, 0);
    },
  );

  testWidgets('offline disables server-status checks for recovery drafts', (
    tester,
  ) async {
    final draft = _draft(
      state: AttendanceDraftState.submissionUncertain,
      sessionDate: DateTime(2026, 7, 19),
    );
    final repository = _PageAcademicRepository();
    final store = _MemoryAttendanceDraftStore([draft]);
    final connectivity = _FakeConnectivityService(NetworkStatus.offline);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
    await _selectFaculty(container);

    await _pumpPage(tester, container);

    final recoveryCard = find.byKey(
      Key('attendance-draft-recovery-${draft.storageKey}'),
    );
    final checkButton = find.descendant(
      of: recoveryCard,
      matching: find.widgetWithText(OutlinedButton, 'Check when online'),
    );
    expect(checkButton, findsOneWidget);
    expect(tester.widget<OutlinedButton>(checkButton).onPressed, isNull);
    expect(repository.submitCount, 0);
    expect(container.read(academicTargetDateProvider), isNull);
  });

  testWidgets('Back to today remains available when a historical load fails', (
    tester,
  ) async {
    final draft = _draft(
      state: AttendanceDraftState.saved,
      sessionDate: DateTime(2026, 7, 19),
    );
    final repository = _PageAcademicRepository(
      historicalLoadError: StateError('historical dashboard unavailable'),
    );
    final store = _MemoryAttendanceDraftStore([draft]);
    final connectivity = _FakeConnectivityService(NetworkStatus.online);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
    await _selectFaculty(container);
    await _pumpPage(tester, container);

    final review = find.widgetWithText(OutlinedButton, 'Review class date');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();

    expect(find.text('Back to today'), findsOneWidget);
    expect(container.read(academicTargetDateProvider), DateTime(2026, 7, 19));
    expect(repository.loadedTargetDates.last, DateTime(2026, 7, 19));

    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();

    expect(container.read(academicTargetDateProvider), isNull);
    expect(repository.loadedTargetDates.last, isNull);
    expect(find.text("Today's assigned classes"), findsOneWidget);
  });

  testWidgets(
    'opening a server-today draft from history returns to today safely',
    (tester) async {
      final pastDraft = _draft(
        state: AttendanceDraftState.saved,
        sessionDate: DateTime(2026, 7, 19),
      );
      final todayDraft = _draft(
        state: AttendanceDraftState.submissionUncertain,
      );
      final repository = _PageAcademicRepository();
      final store = _MemoryAttendanceDraftStore([pastDraft, todayDraft]);
      final connectivity = _FakeConnectivityService(NetworkStatus.online);
      final container = _container(
        repository,
        draftStore: store,
        connectivity: connectivity,
      );
      addTearDown(container.dispose);
      addTearDown(connectivity.close);
      await _selectFaculty(container);
      await _pumpPage(tester, container);

      final reviewPast = find.widgetWithText(
        OutlinedButton,
        'Review class date',
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.ensureVisible(reviewPast);
      await tester.tap(reviewPast);
      await tester.pumpAndSettle();

      expect(container.read(academicTargetDateProvider), DateTime(2026, 7, 19));
      final todayRecoveryCard = find.byKey(
        Key('attendance-draft-recovery-${todayDraft.storageKey}'),
      );
      final checkToday = find.descendant(
        of: todayRecoveryCard,
        matching: find.widgetWithText(OutlinedButton, 'Check server status'),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(checkToday);
      await tester.tap(checkToday);
      await tester.pumpAndSettle();

      expect(container.read(academicTargetDateProvider), isNull);
      expect(repository.loadedTargetDates.last, isNull);
      expect(
        store.drafts
            .singleWhere((draft) => draft.storageKey == todayDraft.storageKey)
            .state,
        AttendanceDraftState.submissionUncertain,
      );
      expect(
        store.drafts
            .singleWhere((draft) => draft.storageKey == todayDraft.storageKey)
            .requestId,
        todayDraft.requestId,
      );
      expect(repository.submitCount, 0);
    },
  );

  testWidgets(
    'historical pending work cannot invoke any attendance submission',
    (tester) async {
      final reconciliationGate = Completer<void>();
      final draft = _draft(
        state: AttendanceDraftState.submissionUncertain,
        sessionDate: DateTime(2026, 7, 19),
      );
      final repository = _PageAcademicRepository();
      final store = _MemoryAttendanceDraftStore([draft], reconciliationGate);
      final connectivity = _FakeConnectivityService(NetworkStatus.online);
      final container = _container(
        repository,
        draftStore: store,
        connectivity: connectivity,
      );
      addTearDown(container.dispose);
      addTearDown(connectivity.close);
      await _selectFaculty(container);
      await _pumpPage(tester, container);

      final check = find.widgetWithText(OutlinedButton, 'Check server status');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      await _expandFacultyClass(tester);

      final historicalSubmit = find.byKey(
        const Key('submit-attendance-entry-1'),
      );
      expect(historicalSubmit, findsOneWidget);
      expect(tester.widget<FilledButton>(historicalSubmit).onPressed, isNull);
      expect(find.textContaining('Past date'), findsWidgets);
      await tester.tap(historicalSubmit, warnIfMissed: false);
      await tester.pump();
      expect(repository.submitCount, 0);

      reconciliationGate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('submit-attendance-entry-1')), findsNothing);
      expect(store.drafts.single.state, AttendanceDraftState.needsReview);
      expect(repository.submitCount, 0);
    },
  );

  testWidgets('historical target resets when the active authority changes', (
    tester,
  ) async {
    final repository = _PageAcademicRepository();
    final store = _MemoryAttendanceDraftStore();
    final connectivity = _FakeConnectivityService(NetworkStatus.online);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
    await _selectFaculty(container);
    await _pumpPage(tester, container);

    container
        .read(academicTargetDateProvider.notifier)
        .show(DateTime(2026, 7, 19));
    await tester.pumpAndSettle();
    expect(find.text('Back to today'), findsOneWidget);
    expect(container.read(academicTargetDateProvider), DateTime(2026, 7, 19));

    await container
        .read(sessionControllerProvider.notifier)
        .selectAccess('development-institution', AppRole.student);
    await tester.pumpAndSettle();

    expect(container.read(academicTargetDateProvider), isNull);
    expect(find.text('Back to today'), findsNothing);
    expect(find.text("Today's timetable"), findsOneWidget);
    expect(repository.loadedTargetDates.last, isNull);
  });

  testWidgets('faculty sees server-confirmed attendance after submit', (
    tester,
  ) async {
    final repository = _PageAcademicRepository();
    final store = _MemoryAttendanceDraftStore();
    final connectivity = _FakeConnectivityService(NetworkStatus.online);
    final container = _container(
      repository,
      draftStore: store,
      connectivity: connectivity,
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
    await _selectFaculty(container);
    await _pumpPage(tester, container);

    expect(find.text("Today's assigned classes"), findsOneWidget);
    await _expandFacultyClass(tester);
    expect(find.text('Ada Student'), findsOneWidget);
    expect(find.text('Lin Student'), findsOneWidget);

    final submit = find.byKey(const Key('submit-attendance-entry-1'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.submitCount, 1);
    expect(repository.lastRequestId, 'widget-request');
    expect(repository.lastMarks, hasLength(2));
    expect(store.drafts, isEmpty);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.byKey(const Key('submit-attendance-entry-1')), findsNothing);
  });
}

ProviderContainer _container(
  AcademicRepository repository, {
  required AttendanceDraftStore draftStore,
  required ConnectivityService connectivity,
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      const AppConfig(
        environment: AppEnvironment.test,
        supabaseUrl: '',
        supabaseAnonKey: '',
        enableDesignSystemGallery: false,
        enableDemoSession: true,
      ),
    ),
    academicRepositoryProvider.overrideWithValue(repository),
    attendanceRequestIdFactoryProvider.overrideWithValue(
      () => 'widget-request',
    ),
    attendanceDraftStoreProvider.overrideWithValue(draftStore),
    connectivityServiceProvider.overrideWithValue(connectivity),
    keyValueStoreProvider.overrideWithValue(_MemoryKeyValueStore()),
  ],
);

Future<void> _selectFaculty(ProviderContainer container) async {
  container.read(sessionControllerProvider);
  await container
      .read(sessionControllerProvider.notifier)
      .selectAccess('development-institution', AppRole.faculty);
}

Future<void> _pumpPage(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: AcademicsPage())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expandFacultyClass(WidgetTester tester) async {
  final facultyClass = find.byKey(const Key('faculty-class-entry-1'));
  await tester.ensureVisible(facultyClass);
  await tester.tap(facultyClass);
  await tester.pumpAndSettle();
}

Future<void> _chooseStatus(
  WidgetTester tester, {
  required String studentUserId,
  required String label,
}) async {
  final dropdown = find.byKey(Key('attendance-status-$studentUserId'));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _PageAcademicRepository implements AcademicRepository {
  _PageAcademicRepository({this.historicalLoadError});

  final Object? historicalLoadError;
  int submitCount = 0;
  String? lastRequestId;
  List<AttendanceMark>? lastMarks;
  final List<DateTime?> loadedTargetDates = [];

  @override
  Future<AcademicDashboard> loadDashboard({
    required String institutionId,
    required AppRole role,
    required DateTime? targetDate,
  }) async {
    loadedTargetDates.add(targetDate);
    final error = historicalLoadError;
    if (targetDate != null && error != null) throw error;
    return _dashboard(
      role: role,
      submitted: false,
      date: targetDate ?? DateTime(2026, 7, 20),
    );
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
    submitCount += 1;
    lastRequestId = requestId;
    lastMarks = List.unmodifiable(marks);
    return _dashboard(
      role: AppRole.faculty,
      submitted: true,
      submittedStatuses: {
        for (final mark in marks) mark.studentUserId: mark.status,
      },
    );
  }
}

AcademicDashboard _dashboard({
  required AppRole role,
  required bool submitted,
  Map<String, AttendanceStatus> submittedStatuses = const {},
  DateTime? date,
}) => AcademicDashboard(
  institutionId: 'development-institution',
  role: role,
  date: date ?? DateTime(2026, 7, 20),
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
      roster: role == AppRole.faculty
          ? [
              RosterStudent(
                enrolmentId: 'enrolment-1',
                userId: 'student-1',
                displayName: 'Ada Student',
                status: submitted ? submittedStatuses['student-1'] : null,
              ),
              RosterStudent(
                enrolmentId: 'enrolment-2',
                userId: 'student-2',
                displayName: 'Lin Student',
                status: submitted ? submittedStatuses['student-2'] : null,
              ),
            ]
          : const [],
    ),
  ],
  attendanceSummary: role == AppRole.student
      ? const [
          SubjectAttendanceSummary(
            courseOfferingId: 'offering-1',
            subjectCode: 'CS701',
            subjectName: 'Distributed Systems',
            attendedSessions: 17,
            totalSessions: 20,
            excusedSessions: 1,
            percentage: 85,
          ),
        ]
      : const [],
);

AttendanceDraft _draft({
  required AttendanceDraftState state,
  DateTime? sessionDate,
  String courseOfferingId = 'offering-1',
  String timetableEntryId = 'entry-1',
  String subjectCode = 'CS701',
  String subjectName = 'Distributed Systems',
  String startsAt = '09:00',
  String endsAt = '10:00',
}) {
  final now = DateTime.utc(2026, 7, 20, 8);
  return AttendanceDraft(
    userId: 'development-user',
    membershipId: 'development-membership',
    institutionId: 'development-institution',
    selectionKey: 'development-institution:faculty',
    courseOfferingId: courseOfferingId,
    timetableEntryId: timetableEntryId,
    subjectCode: subjectCode,
    subjectName: subjectName,
    startsAt: startsAt,
    endsAt: endsAt,
    sessionDate: sessionDate ?? DateTime(2026, 7, 20),
    roster: const [
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-1',
        userId: 'student-1',
      ),
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-2',
        userId: 'student-2',
      ),
    ],
    statuses: const {
      'student-1': AttendanceStatus.absent,
      'student-2': AttendanceStatus.present,
    },
    state: state,
    requestId: state == AttendanceDraftState.submissionUncertain
        ? 'pending-request'
        : null,
    createdAt: now,
    updatedAt: now,
  );
}

class _MemoryAttendanceDraftStore implements AttendanceDraftStore {
  _MemoryAttendanceDraftStore([
    List<AttendanceDraft> initial = const [],
    this.upsertGate,
  ]) : _drafts = {for (final draft in initial) draft.storageKey: draft};

  final Map<String, AttendanceDraft> _drafts;
  final Completer<void>? upsertGate;

  List<AttendanceDraft> get drafts => List.unmodifiable(_drafts.values);

  @override
  Future<void> delete(String storageKey) async {
    _drafts.remove(storageKey);
  }

  @override
  Future<void> deleteAll() async {
    _drafts.clear();
  }

  @override
  Future<void> deleteForUser(String userId) async {
    _drafts.removeWhere((_, draft) => draft.userId == userId);
  }

  @override
  Future<List<AttendanceDraft>> loadAll() async => drafts;

  @override
  Future<void> upsert(AttendanceDraft draft) async {
    await upsertGate?.future;
    _drafts[draft.storageKey] = draft;
  }
}

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._current);

  NetworkStatus _current;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get changes => _controller.stream;

  @override
  Future<NetworkStatus> current() async => _current;

  void emit(NetworkStatus status) {
    _current = status;
    _controller.add(status);
  }

  Future<void> close() => _controller.close();
}

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
