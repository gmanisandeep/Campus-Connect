import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/presentation/controllers/affiliation_controller.dart';
import 'package:campus_connect/features/affiliation/presentation/pages/affiliation_review_page.dart';
import 'package:campus_connect/features/affiliation/presentation/widgets/student_affiliation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'student form asks for batch and progression, not a claimed year',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_SignedOutSession.new),
            studentAffiliationControllerProvider.overrideWith(
              _NewStudentController.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: StudentAffiliationPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Batch start year'), findsOneWidget);
      expect(find.text('Expected completion year'), findsOneWidget);
      expect(find.text('Progression status'), findsOneWidget);
      expect(find.text('Current study year'), findsNothing);

      await tester.ensureVisible(find.text('Regular progression'));
      await tester.tap(find.text('Regular progression'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Graduated'));
      await tester.pumpAndSettle();

      expect(find.text('Completion year'), findsOneWidget);
      expect(find.text('Expected completion year'), findsNothing);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.textContaining('receive Alumni access'), findsOneWidget);
    },
  );

  testWidgets('pending student state remains readable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_SignedOutSession.new),
          studentAffiliationControllerProvider.overrideWith(
            _PendingStudentController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: StudentAffiliationPanel(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approval pending'), findsOneWidget);
    expect(find.text('CC-42'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
  });

  testWidgets('administrator queue preserves actions at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          affiliationReviewControllerProvider.overrideWith(
            _ReviewQueueController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const Scaffold(body: AffiliationReviewPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student verification'), findsOneWidget);
    expect(find.text('Student Name'), findsOneWidget);
    expect(find.text('Approve student'), findsOneWidget);
    expect(find.text('Reject request'), findsOneWidget);

    await tester.ensureVisible(find.text('Approve student'));
    await tester.tap(find.text('Approve student'));
    await tester.pumpAndSettle();

    expect(find.text('College-verified current year'), findsOneWidget);
    expect(find.text('Year 1'), findsOneWidget);
    await tester.tap(find.text('Year 1'));
    await tester.pumpAndSettle();
    expect(find.text('Year 3'), findsOneWidget);
  });

  testWidgets('graduate approval grants Alumni without a current-year field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          affiliationReviewControllerProvider.overrideWith(
            _GraduateReviewQueueController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: AffiliationReviewPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Approve student'));
    await tester.tap(find.text('Approve student'));
    await tester.pumpAndSettle();

    expect(find.text('Approve Alumni access?'), findsOneWidget);
    expect(find.text('College-verified current year'), findsNothing);
    expect(find.textContaining('No current academic year'), findsOneWidget);
  });
}

class _NewStudentController extends StudentAffiliationController {
  @override
  Future<StudentAffiliationOverview> build() async =>
      const StudentAffiliationOverview(
        institutions: [
          InstitutionChoice(id: 'campus-1', name: 'Example College'),
        ],
        programmes: [
          ProgrammeChoice(
            id: 'programme-1',
            institutionId: 'campus-1',
            name: 'Computer Science',
            durationMonths: 36,
          ),
        ],
        request: null,
      );
}

class _SignedOutSession extends SessionController {
  @override
  AppSession build() => const AppSession.signedOut();
}

class _PendingStudentController extends StudentAffiliationController {
  @override
  Future<StudentAffiliationOverview> build() async =>
      StudentAffiliationOverview(
        institutions: const [
          InstitutionChoice(id: 'campus-1', name: 'Example College'),
        ],
        programmes: const [
          ProgrammeChoice(
            id: 'programme-1',
            institutionId: 'campus-1',
            name: 'Computer Science',
            durationMonths: 36,
          ),
        ],
        request: _request(),
      );
}

class _ReviewQueueController extends AffiliationReviewController {
  @override
  Future<List<StudentAffiliationRequest>> build() async => [_request()];
}

class _GraduateReviewQueueController extends AffiliationReviewController {
  @override
  Future<List<StudentAffiliationRequest>> build() async => [
    _request(progressionStatus: StudentProgressionStatus.graduated),
  ];
}

StudentAffiliationRequest _request({
  StudentProgressionStatus progressionStatus = StudentProgressionStatus.regular,
}) => StudentAffiliationRequest(
  id: 'request-1',
  institutionId: 'campus-1',
  institutionName: 'Example College',
  officialName: 'Student Name',
  rollNumber: 'CC-42',
  programmeId: 'programme-1',
  programme: 'Computer Science',
  durationMonths: 36,
  batchStartYear: 2023,
  expectedCompletionYear: 2026,
  progressionStatus: progressionStatus,
  verifiedCurrentYear: null,
  status: AffiliationRequestStatus.pending,
  createdAt: DateTime.utc(2026, 8, 4, 8),
  updatedAt: DateTime.utc(2026, 8, 4, 8),
  userId: 'student-1',
  email: 'student@example.edu',
);
