import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/routing/role_aware_shell.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:campus_connect/features/academics/presentation/pages/academics_page.dart';
import 'package:campus_connect/features/foundation/presentation/pages/design_system_gallery_page.dart';
import 'package:campus_connect/features/home/presentation/pages/home_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/access_unavailable_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/forgot_password_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/reset_password_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/sign_in_page.dart';
import 'package:campus_connect/features/onboarding/presentation/pages/splash_page.dart';
import 'package:campus_connect/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String? routeRedirect({
  required AppSession session,
  required String location,
  required bool galleryEnabled,
  required bool academicsEnabled,
}) {
  if (location == '/design-system' && galleryEnabled) return null;

  switch (session.status) {
    case SessionStatus.unknown:
      return location == '/splash' ? null : '/splash';
    case SessionStatus.signedOut:
      const publicRoutes = {'/sign-in', '/forgot-password'};
      return publicRoutes.contains(location) ? null : '/sign-in';
    case SessionStatus.passwordRecovery:
      return location == '/reset-password' ? null : '/reset-password';
    case SessionStatus.onboarding:
    case SessionStatus.selectionRequired:
      return location == '/onboarding' ? null : '/onboarding';
    case SessionStatus.accessBlocked:
      return location == '/access-unavailable' ? null : '/access-unavailable';
    case SessionStatus.authenticated:
      const identityRoutes = {
        '/splash',
        '/sign-in',
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
    ),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
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
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
