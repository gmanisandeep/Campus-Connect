import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Student Home exposes only truthful available academic actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _HomeTestApp(
        session: _session(
          role: AppRole.student,
          permissions: const {AppPermission.attendanceReadOwn},
        ),
      ),
    );

    expect(find.textContaining('Avery'), findsOneWidget);
    expect(find.text('Jump back in'), findsOneWidget);
    expect(find.text("Today's timetable"), findsOneWidget);
    expect(find.text('Schedule and attendance'), findsOneWidget);
    expect(find.text('Campus feed'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
    expect(find.text('Chat'), findsNothing);
  });

  testWidgets('Faculty Home uses the Teaching vocabulary and authority copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _HomeTestApp(
        session: _session(
          role: AppRole.faculty,
          permissions: const {
            AppPermission.rosterRead,
            AppPermission.attendanceRecord,
          },
        ),
      ),
    );

    expect(find.text('Jump back into teaching'), findsOneWidget);
    expect(find.text("Today's classes"), findsOneWidget);
    expect(find.text('Classes and rosters'), findsOneWidget);
    expect(find.text('Campus feed'), findsOneWidget);
  });
}

class _HomeTestApp extends StatelessWidget {
  const _HomeTestApp({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(_configuredApp),
      sessionControllerProvider.overrideWith(
        () => _FixedSessionController(session),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: HomePage()),
    ),
  );
}

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.initialSession);

  final AppSession initialSession;

  @override
  AppSession build() => initialSession;
}

AppSession _session({
  required AppRole role,
  required Set<AppPermission> permissions,
}) {
  final grant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'North Valley Institute',
    role: role,
    permissions: permissions,
  );
  final identity = IdentityContext(
    userId: 'user',
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
  return AppSession.authenticated(identity: identity, activeGrant: grant);
}

const _configuredApp = AppConfig(
  environment: AppEnvironment.test,
  supabaseUrl: 'https://campus.example.com',
  supabaseAnonKey: 'sb_publishable_test_public_key',
  enableDesignSystemGallery: false,
  enableDemoSession: false,
);
