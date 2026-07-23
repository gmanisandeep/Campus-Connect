import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';

enum SessionStatus {
  unknown,
  signedOut,
  passwordRecovery,
  onboarding,
  selectionRequired,
  authenticated,
  accessBlocked,
}

enum AccessBlockReason {
  noMembership,
  suspended,
  inactiveInstitution,
  expiredInvitation,
  missingRole,
  unavailable,
}

class AppSession {
  const AppSession._({
    required this.status,
    this.identity,
    this.activeGrant,
    this.blockReason,
  });

  const AppSession.unknown() : this._(status: SessionStatus.unknown);
  const AppSession.signedOut() : this._(status: SessionStatus.signedOut);
  const AppSession.passwordRecovery()
    : this._(status: SessionStatus.passwordRecovery);
  const AppSession.onboarding(IdentityContext identity)
    : this._(status: SessionStatus.onboarding, identity: identity);
  const AppSession.selectionRequired(IdentityContext identity)
    : this._(status: SessionStatus.selectionRequired, identity: identity);
  const AppSession.authenticated({
    required IdentityContext identity,
    required AccessGrant activeGrant,
  }) : this._(
         status: SessionStatus.authenticated,
         identity: identity,
         activeGrant: activeGrant,
       );
  const AppSession.accessBlocked({
    required AccessBlockReason reason,
    IdentityContext? identity,
  }) : this._(
         status: SessionStatus.accessBlocked,
         identity: identity,
         blockReason: reason,
       );

  final SessionStatus status;
  final IdentityContext? identity;
  final AccessGrant? activeGrant;
  final AccessBlockReason? blockReason;

  String? get userId => identity?.userId;
  String? get displayName => identity?.displayName;
  String? get institutionId => activeGrant?.institutionId;
  String? get institutionName => activeGrant?.institutionName;
  AppRole? get activeRole => activeGrant?.role;
  Set<AppPermission> get permissions =>
      activeGrant?.permissions ?? const <AppPermission>{};
  List<AccessGrant> get availableGrants =>
      identity?.activeGrants ?? const <AccessGrant>[];
  Set<AppRole> get availableRoles => {
    for (final grant in availableGrants) grant.role,
  };

  bool get isAuthenticated => status == SessionStatus.authenticated;
  bool can(AppPermission permission) => permissions.contains(permission);

  AppSession selectAccess(String targetInstitutionId, AppRole targetRole) {
    final currentIdentity = identity;
    if (currentIdentity == null ||
        !currentIdentity.profileCompleted ||
        (status != SessionStatus.authenticated &&
            status != SessionStatus.selectionRequired)) {
      return this;
    }
    final grant = currentIdentity.findGrant(targetInstitutionId, targetRole);
    if (grant == null) return this;
    return AppSession.authenticated(
      identity: currentIdentity,
      activeGrant: grant,
    );
  }
}
