import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/features/identity/data/identity_context_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = IdentityContextMapper();

  test('maps role-scoped grants and ignores unknown capabilities', () {
    final context = mapper.fromJson({
      'user_id': 'user-1',
      'profile': {
        'display_name': 'Test Student',
        'profile_completed_at': '2026-07-17T10:00:00Z',
      },
      'memberships': [
        {
          'id': 'membership-1',
          'institution_id': 'institution-1',
          'institution_name': 'Example Campus',
          'institution_active': true,
          'status': 'active',
          'invitation_expires_at': null,
          'roles': [
            {
              'key': 'student',
              'label': 'Student',
              'permissions': ['attendance_read_own', 'future_permission'],
            },
            {
              'key': 'future_role',
              'label': 'Future role',
              'permissions': ['attendance_record'],
            },
          ],
        },
      ],
    });

    expect(context.userId, 'user-1');
    expect(context.profileCompleted, isTrue);
    expect(context.memberships.single.status, MembershipStatus.active);
    expect(context.activeGrants, hasLength(1));
    expect(context.activeGrants.single.role, AppRole.student);
    expect(context.activeGrants.single.permissions, {
      AppPermission.attendanceReadOwn,
    });
  });

  test('rejects malformed identity payloads', () {
    expect(
      () => mapper.fromJson({'memberships': <Object?>[]}),
      throwsFormatException,
    );
  });
}
