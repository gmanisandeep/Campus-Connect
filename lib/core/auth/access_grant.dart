import 'package:campus_connect/core/auth/app_role.dart';

enum MembershipStatus {
  invited,
  active,
  suspended,
  left,
  unknown;

  static MembershipStatus fromDatabaseValue(String value) => switch (value) {
    'invited' => MembershipStatus.invited,
    'active' => MembershipStatus.active,
    'suspended' => MembershipStatus.suspended,
    'left' => MembershipStatus.left,
    _ => MembershipStatus.unknown,
  };
}

class AccessGrant {
  const AccessGrant({
    required this.membershipId,
    required this.institutionId,
    required this.institutionName,
    required this.role,
    required this.permissions,
  });

  final String membershipId;
  final String institutionId;
  final String institutionName;
  final AppRole role;
  final Set<AppPermission> permissions;

  String get selectionKey => '$institutionId:${role.databaseKey}';

  bool matches(String targetInstitutionId, AppRole targetRole) =>
      institutionId == targetInstitutionId && role == targetRole;
}

class MembershipSummary {
  const MembershipSummary({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.institutionActive,
    required this.status,
    required this.grants,
    this.invitationExpiresAt,
  });

  final String id;
  final String institutionId;
  final String institutionName;
  final bool institutionActive;
  final MembershipStatus status;
  final DateTime? invitationExpiresAt;
  final List<AccessGrant> grants;

  bool get invitationExpired {
    final expiresAt = invitationExpiresAt;
    return expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc());
  }

  bool get canAcceptInvitation =>
      status == MembershipStatus.invited &&
      institutionActive &&
      !invitationExpired &&
      grants.isNotEmpty;
}

class IdentityContext {
  const IdentityContext({
    required this.userId,
    required this.profileCompleted,
    required this.memberships,
    this.displayName,
  });

  final String userId;
  final String? displayName;
  final bool profileCompleted;
  final List<MembershipSummary> memberships;

  List<AccessGrant> get activeGrants => [
    for (final membership in memberships)
      if (membership.status == MembershipStatus.active &&
          membership.institutionActive)
        ...membership.grants,
  ];

  List<MembershipSummary> get acceptableInvitations => [
    for (final membership in memberships)
      if (membership.canAcceptInvitation) membership,
  ];

  AccessGrant? findGrant(String institutionId, AppRole role) {
    for (final grant in activeGrants) {
      if (grant.matches(institutionId, role)) return grant;
    }
    return null;
  }
}
