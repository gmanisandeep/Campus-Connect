import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/routing/role_aware_shell.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact Faculty shell exposes Teaching and active context', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _ShellTestApp(
        textScale: 2,
        session: _session(
          role: AppRole.faculty,
          permissions: const {
            AppPermission.rosterRead,
            AppPermission.attendanceRecord,
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CcNavigationBar), findsOneWidget);
    expect(find.byType(CcNavigationRail), findsNothing);
    expect(find.text('Teaching'), findsOneWidget);
    expect(find.text('North Valley Institute'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide shell switches structurally to a navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _ShellTestApp(
        session: _session(
          role: AppRole.student,
          permissions: const {AppPermission.attendanceReadOwn},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CcNavigationRail), findsOneWidget);
    expect(find.byType(CcNavigationBar), findsNothing);
    expect(find.text('Academics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ShellTestApp extends StatelessWidget {
  const _ShellTestApp({required this.session, this.textScale = 1});

  final AppSession session;
  final double textScale;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(_configuredApp),
      sessionControllerProvider.overrideWith(
        () => _FixedSessionController(session),
      ),
      connectivityProvider.overrideWith(
        (ref) => Stream.value(NetworkStatus.online),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const RoleAwareShell(
        location: '/home',
        child: ColoredBox(color: Colors.transparent),
      ),
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
