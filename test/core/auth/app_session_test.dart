import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const studentGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Example Campus',
    role: AppRole.student,
    permissions: {AppPermission.attendanceReadOwn},
  );
  const facultyGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Example Campus',
    role: AppRole.faculty,
    permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
  );
  const identity = IdentityContext(
    userId: 'user',
    displayName: 'Example User',
    profileCompleted: true,
    memberships: [
      MembershipSummary(
        id: 'membership',
        institutionId: 'institution',
        institutionName: 'Example Campus',
        institutionActive: true,
        status: MembershipStatus.active,
        grants: [studentGrant, facultyGrant],
      ),
    ],
  );

  test('access selection is limited to server-provided grants', () {
    const session = AppSession.authenticated(
      identity: identity,
      activeGrant: studentGrant,
    );

    final facultySession = session.selectAccess('institution', AppRole.faculty);
    expect(facultySession.activeRole, AppRole.faculty);
    expect(facultySession.can(AppPermission.attendanceRecord), isTrue);
    expect(facultySession.can(AppPermission.attendanceReadOwn), isFalse);

    final rejected = session.selectAccess(
      'another-institution',
      AppRole.institutionAdministrator,
    );
    expect(rejected.activeGrant, same(studentGrant));
  });

  test('permission checks never infer authority from role labels', () {
    const emptyFacultyGrant = AccessGrant(
      membershipId: 'membership',
      institutionId: 'institution',
      institutionName: 'Example Campus',
      role: AppRole.faculty,
      permissions: {},
    );
    const session = AppSession.authenticated(
      identity: identity,
      activeGrant: emptyFacultyGrant,
    );

    expect(session.can(AppPermission.attendanceRecord), isFalse);
  });

  test('access selection cannot bypass incomplete-profile onboarding', () {
    const incompleteIdentity = IdentityContext(
      userId: 'incomplete-user',
      profileCompleted: false,
      memberships: [
        MembershipSummary(
          id: 'membership',
          institutionId: 'institution',
          institutionName: 'Example Campus',
          institutionActive: true,
          status: MembershipStatus.active,
          grants: [studentGrant, facultyGrant],
        ),
      ],
    );
    const session = AppSession.onboarding(incompleteIdentity);

    final rejected = session.selectAccess('institution', AppRole.student);

    expect(rejected, same(session));
    expect(rejected.isAuthenticated, isFalse);
    expect(rejected.permissions, isEmpty);
  });
}
