import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/features/social/data/supabase_social_repository.dart';
import 'package:campus_connect/features/social/domain/social.dart';
import 'package:campus_connect/features/social/domain/social_repository.dart';
import 'package:campus_connect/features/social/presentation/pages/social_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending members receive the complete social navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SocialHubPage(provisional: true)));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Your campus world starts here'), findsOneWidget);
    expect(find.textContaining('Social access is active'), findsOneWidget);
    expect(
      find.textContaining('Attendance, Calendar, Courses'),
      findsOneWidget,
    );
  });

  testWidgets(
    'feed renders real server posts and complete interaction affordances',
    (tester) async {
      final repository = _FakeSocialRepository(
        posts: [
          SocialPost(
            id: 'post-1',
            authorUserId: 'author-1',
            authorName: 'Campus Publisher',
            username: 'campus_publisher',
            body: 'A real server-provided campus update.',
            publishedAt: DateTime.now(),
            media: const [],
            likeCount: 4,
            commentCount: 2,
            repostCount: 1,
            likedByViewer: false,
            savedByViewer: false,
            isOfficial: true,
            isCollegeVerified: true,
            institutionName: 'Verified College',
          ),
        ],
      );
      await tester.pumpWidget(
        _app(const SocialHubPage(), repository: repository),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('A real server-provided campus update.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Like'), findsOneWidget);
      expect(find.byTooltip('Comments'), findsOneWidget);
      expect(find.byTooltip('Repost'), findsOneWidget);
      expect(find.byTooltip('Save post'), findsOneWidget);
      expect(find.byTooltip('Share post'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.semanticLabel == 'Official college account',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('professional profile exposes truthful college verification', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const SocialHubPage(initialSection: 4), session: _verifiedSession()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avery Morgan'), findsOneWidget);
    expect(find.text('@viewer_one'), findsOneWidget);
    expect(find.text('Student · North Valley Institute'), findsOneWidget);
    expect(find.text('College verified'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Professional bio'), findsOneWidget);
    expect(find.text('Message requests'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });
}

Widget _app(
  Widget child, {
  SocialRepository? repository,
  AppSession? session,
}) => ProviderScope(
  overrides: [
    socialRepositoryProvider.overrideWithValue(
      repository ?? const _FakeSocialRepository(),
    ),
    if (session != null)
      sessionControllerProvider.overrideWith(
        () => _FixedSessionController(session),
      ),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: child,
  ),
);

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.initialSession);

  final AppSession initialSession;

  @override
  AppSession build() => initialSession;
}

AppSession _verifiedSession() {
  const grant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'North Valley Institute',
    role: AppRole.student,
    permissions: {},
  );
  const identity = IdentityContext(
    userId: 'viewer-1',
    displayName: 'Avery Morgan',
    profileCompleted: true,
    memberships: [
      MembershipSummary(
        id: 'membership',
        institutionId: 'institution',
        institutionName: 'North Valley Institute',
        institutionActive: true,
        status: MembershipStatus.active,
        grants: [grant],
      ),
    ],
  );
  return const AppSession.authenticated(identity: identity, activeGrant: grant);
}

class _FakeSocialRepository implements SocialRepository {
  const _FakeSocialRepository({this.posts = const []});

  final List<SocialPost> posts;

  @override
  Future<SocialProfile> ensureProfile() async => const SocialProfile(
    userId: 'viewer-1',
    username: 'viewer_one',
    bio: '',
    isPublic: true,
    allowMessageRequests: 'everyone',
  );

  @override
  Future<List<SocialPost>> loadFeed(SocialFeedMode mode) async => posts;

  @override
  Future<SocialInbox> loadInbox() async =>
      const SocialInbox(requests: [], threads: []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
