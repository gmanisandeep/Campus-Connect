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
}

Widget _app(Widget child, {SocialRepository? repository}) => ProviderScope(
  overrides: [
    socialRepositoryProvider.overrideWithValue(
      repository ?? const _FakeSocialRepository(),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: child,
  ),
);

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
