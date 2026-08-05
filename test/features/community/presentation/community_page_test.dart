import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/features/community/domain/community.dart';
import 'package:campus_connect/features/community/domain/community_repository.dart';
import 'package:campus_connect/features/community/presentation/controllers/community_controller.dart';
import 'package:campus_connect/features/community/presentation/pages/community_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'pending students see Community while academic tools remain explicitly locked',
    (tester) async {
      final repository = _CommunityRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_PendingSession.new),
            communityRepositoryProvider.overrideWithValue(repository),
            communityOverviewControllerProvider.overrideWith(
              _CommunityController.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: CommunityPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Campus Feed'), findsOneWidget);
      expect(find.textContaining('Community access is active'), findsOneWidget);
      expect(
        find.textContaining('Attendance, Calendar, Courses'),
        findsOneWidget,
      );
      expect(find.text('No official updates yet'), findsOneWidget);

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('Verified Faculty'), findsOneWidget);

      await tester.tap(find.text('Verified Faculty'));
      await tester.pumpAndSettle();
      expect(find.text('Start the conversation'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('community-message-composer')),
        'Hello Faculty',
      );
      await tester.tap(find.byKey(const Key('send-community-message')));
      await tester.pumpAndSettle();

      expect(find.text('Hello Faculty'), findsOneWidget);
      expect(repository.sentFacultyUserId, 'faculty-1');
    },
  );

  testWidgets('Community adapts to landscape, large text, and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_PendingSession.new),
          communityRepositoryProvider.overrideWithValue(_CommunityRepository()),
          communityOverviewControllerProvider.overrideWith(
            _CommunityController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: const Scaffold(body: CommunityPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus Feed'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('No official updates yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CommunityController extends CommunityOverviewController {
  @override
  Future<CommunityOverview> build() async => _overview;
}

class _PendingSession extends SessionController {
  @override
  AppSession build() => const AppSession.accessBlocked(
    reason: AccessBlockReason.noMembership,
    identity: IdentityContext(
      userId: 'student-1',
      displayName: 'Pending Student',
      profileCompleted: true,
      memberships: [],
    ),
  );
}

class _CommunityRepository implements CommunityRepository {
  String? sentFacultyUserId;

  @override
  Future<CommunityOverview> loadOverview(String? institutionId) async =>
      _overview;

  @override
  Future<CommunityConversation> loadConversation(String threadId) async =>
      CommunityConversation(threadId: threadId, messages: const []);

  @override
  Future<CommunityConversation> sendMessage({
    required String institutionId,
    required String? threadId,
    required String? facultyUserId,
    required String clientMessageId,
    required String body,
  }) async {
    sentFacultyUserId = facultyUserId;
    return CommunityConversation(
      threadId: 'thread-1',
      messages: [
        CommunityMessage(
          id: 'message-1',
          threadId: 'thread-1',
          senderUserId: 'student-1',
          body: body,
          sentAt: DateTime.utc(2026, 8, 5, 1, 2),
        ),
      ],
    );
  }
}

final _overview = CommunityOverview(
  institutionId: 'campus-1',
  institutionName: 'Example College',
  accessState: CommunityAccessState.pendingVerification,
  viewerKind: CommunityViewerKind.student,
  feed: const [],
  contacts: const [
    CommunityContact(
      participantUserId: 'faculty-1',
      participantName: 'Verified Faculty',
      participantRole: 'Faculty',
    ),
  ],
);
