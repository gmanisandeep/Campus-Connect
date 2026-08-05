import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/routing/role_aware_shell.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:campus_connect/features/academics/presentation/pages/academics_page.dart';
import 'package:campus_connect/features/affiliation/presentation/pages/affiliation_review_page.dart';
import 'package:campus_connect/features/college_console/presentation/college_console_pages.dart';
import 'package:campus_connect/features/community/presentation/pages/community_page.dart';
import 'package:campus_connect/features/foundation/presentation/pages/design_system_gallery_page.dart';
import 'package:campus_connect/features/home/presentation/pages/home_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/access_unavailable_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/forgot_password_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/reset_password_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/sign_in_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/sign_up_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/splash_page.dart';
import 'package:campus_connect/features/profile/presentation/pages/profile_page.dart';
import 'package:campus_connect/features/social/presentation/pages/social_hub_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String? routeRedirect({
  required AppSession session,
  required String location,
  required bool galleryEnabled,
  required bool academicsEnabled,
  bool communityEnabled = true,
}) {
  if (location == '/design-system' && galleryEnabled) return null;

  switch (session.status) {
    case SessionStatus.unknown:
      return location == '/splash' ? null : '/splash';
    case SessionStatus.signedOut:
      const publicRoutes = {'/sign-in', '/sign-up', '/forgot-password'};
      return publicRoutes.contains(location) ? null : '/sign-in';
    case SessionStatus.passwordRecovery:
      return location == '/reset-password' ? null : '/reset-password';
    case SessionStatus.onboarding:
    case SessionStatus.selectionRequired:
      return location == '/onboarding' ? null : '/onboarding';
    case SessionStatus.accessBlocked:
      if (location == '/college-registration' ||
          location == '/faculty-registration' ||
          location == '/platform-admin') {
        return null;
      }
      return location == '/access-unavailable' ? null : '/access-unavailable';
    case SessionStatus.authenticated:
      const identityRoutes = {
        '/splash',
        '/sign-in',
        '/sign-up',
        '/forgot-password',
        '/reset-password',
        '/onboarding',
        '/access-unavailable',
      };
      if (identityRoutes.contains(location)) return '/home';
      if ((location == '/academics' || location.startsWith('/academics/')) &&
          (!academicsEnabled || !canViewAcademics(session.activeGrant))) {
        return '/home';
      }
      if ((location == '/community' || location.startsWith('/community/')) &&
          !communityEnabled) {
        return '/home';
      }
      if ((location == '/social' || location.startsWith('/social/')) &&
          !communityEnabled) {
        return '/home';
      }
      if (location == '/affiliation-review' &&
          !session.can(AppPermission.institutionManage)) {
        return '/home';
      }
      if (location == '/college-admin' &&
          !session.can(AppPermission.institutionManage)) {
        return '/home';
      }
      return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => routeRedirect(
      session: session,
      location: state.matchedLocation,
      galleryEnabled: config.enableDesignSystemGallery,
      academicsEnabled:
          config.hasBackendConfiguration && !config.enableDemoSession,
      communityEnabled:
          config.hasBackendConfiguration && !config.enableDemoSession,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/access-unavailable',
        builder: (context, state) => const AccessUnavailablePage(),
      ),
      GoRoute(
        path: '/social',
        builder: (context, state) => SocialHubPage(
          initialSection:
              int.tryParse(state.uri.queryParameters['section'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/college-registration',
        builder: (context, state) => const CollegeRegistrationPage(),
      ),
      GoRoute(
        path: '/faculty-registration',
        builder: (context, state) => const FacultyRegistrationPage(),
      ),
      GoRoute(
        path: '/college-admin',
        builder: (context, state) => const CollegeAdminConsolePage(),
      ),
      GoRoute(
        path: '/platform-admin',
        builder: (context, state) => const PlatformReviewConsolePage(),
      ),
      if (config.enableDesignSystemGallery)
        GoRoute(
          path: '/design-system',
          builder: (context, state) => const DesignSystemGalleryPage(),
        ),
      ShellRoute(
        builder: (context, state, child) =>
            RoleAwareShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/academics',
            builder: (context, state) => const AcademicsPage(),
          ),
          GoRoute(
            path: '/community',
            redirect: (context, state) => '/social',
            builder: (context, state) => const CommunityPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/affiliation-review',
            builder: (context, state) => const AffiliationReviewPage(),
          ),
        ],
      ),
    ],
  );
});
