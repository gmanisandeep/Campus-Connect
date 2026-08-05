import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const identity = IdentityContext(
    userId: 'user',
    displayName: 'Test User',
    profileCompleted: true,
    memberships: [],
  );
  const studentGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Campus',
    role: AppRole.student,
    permissions: {AppPermission.attendanceReadOwn},
  );
  const facultyGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Campus',
    role: AppRole.faculty,
    permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
  );
  const unsupportedGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Campus',
    role: AppRole.clubCoordinator,
    permissions: {AppPermission.clubsManage},
  );
  const institutionAdministratorGrant = AccessGrant(
    membershipId: 'admin-membership',
    institutionId: 'institution',
    institutionName: 'Campus',
    role: AppRole.institutionAdministrator,
    permissions: {AppPermission.institutionManage},
  );

  test('unknown and signed-out sessions cannot render protected routes', () {
    expect(
      routeRedirect(
        session: const AppSession.unknown(),
        location: '/home',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/splash',
    );
    expect(
      routeRedirect(
        session: const AppSession.signedOut(),
        location: '/home',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/sign-in',
    );
    expect(
      routeRedirect(
        session: const AppSession.signedOut(),
        location: '/forgot-password',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      isNull,
    );
    expect(
      routeRedirect(
        session: const AppSession.signedOut(),
        location: '/sign-up',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      isNull,
    );
  });

  test('identity flow statuses are routed deterministically', () {
    expect(
      routeRedirect(
        session: const AppSession.passwordRecovery(),
        location: '/home',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/reset-password',
    );
    expect(
      routeRedirect(
        session: const AppSession.onboarding(identity),
        location: '/home',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/onboarding',
    );
  });

  test('authenticated sessions leave identity routes for the app shell', () {
    const authenticated = AppSession.authenticated(
      identity: identity,
      activeGrant: studentGrant,
    );

    expect(
      routeRedirect(
        session: authenticated,
        location: '/onboarding',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/home',
    );
    expect(
      routeRedirect(
        session: authenticated,
        location: '/sign-up',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/home',
    );
    expect(
      routeRedirect(
        session: authenticated,
        location: '/home',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      isNull,
    );
    expect(
      routeRedirect(
        session: authenticated,
        location: '/profile',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      isNull,
    );
  });

  test(
    'academics requires an enabled backend and an eligible active grant',
    () {
      const student = AppSession.authenticated(
        identity: identity,
        activeGrant: studentGrant,
      );
      const faculty = AppSession.authenticated(
        identity: identity,
        activeGrant: facultyGrant,
      );
      const unsupported = AppSession.authenticated(
        identity: identity,
        activeGrant: unsupportedGrant,
      );

      expect(
        routeRedirect(
          session: student,
          location: '/academics',
          galleryEnabled: false,
          academicsEnabled: true,
        ),
        isNull,
      );
      expect(
        routeRedirect(
          session: faculty,
          location: '/academics',
          galleryEnabled: false,
          academicsEnabled: true,
        ),
        isNull,
      );
      expect(
        routeRedirect(
          session: unsupported,
          location: '/academics',
          galleryEnabled: false,
          academicsEnabled: true,
        ),
        '/home',
      );
      expect(
        routeRedirect(
          session: student,
          location: '/academics/offering-1',
          galleryEnabled: false,
          academicsEnabled: false,
        ),
        '/home',
      );
    },
  );

  test('affiliation review requires institution management permission', () {
    const student = AppSession.authenticated(
      identity: identity,
      activeGrant: studentGrant,
    );
    const administrator = AppSession.authenticated(
      identity: identity,
      activeGrant: institutionAdministratorGrant,
    );

    expect(
      routeRedirect(
        session: student,
        location: '/affiliation-review',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      '/home',
    );
    expect(
      routeRedirect(
        session: administrator,
        location: '/affiliation-review',
        galleryEnabled: false,
        academicsEnabled: true,
      ),
      isNull,
    );
  });

  test(
    'Community requires backend configuration but not academic permission',
    () {
      const student = AppSession.authenticated(
        identity: identity,
        activeGrant: studentGrant,
      );
      const unsupported = AppSession.authenticated(
        identity: identity,
        activeGrant: unsupportedGrant,
      );

      expect(
        routeRedirect(
          session: student,
          location: '/community',
          galleryEnabled: false,
          academicsEnabled: true,
          communityEnabled: true,
        ),
        isNull,
      );
      expect(
        routeRedirect(
          session: unsupported,
          location: '/community',
          galleryEnabled: false,
          academicsEnabled: true,
          communityEnabled: true,
        ),
        isNull,
      );
      expect(
        routeRedirect(
          session: student,
          location: '/community',
          galleryEnabled: false,
          academicsEnabled: true,
          communityEnabled: false,
        ),
        '/home',
      );
    },
  );
}
