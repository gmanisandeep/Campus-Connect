import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';

class IdentityContextMapper {
  const IdentityContextMapper();

  IdentityContext fromJson(Object? value) {
    final root = _map(value, 'identity context');
    final userId = _requiredString(root, 'user_id');
    final profileValue = root['profile'];
    final profile = profileValue == null
        ? const <String, Object?>{}
        : _map(profileValue, 'profile');
    final displayName = _optionalString(profile['display_name']);
    final profileCompleted = profile['profile_completed_at'] != null;
    final memberships = <MembershipSummary>[];

    for (final value in _list(root['memberships'], 'memberships')) {
      final membership = _map(value, 'membership');
      final membershipId = _requiredString(membership, 'id');
      final institutionId = _requiredString(membership, 'institution_id');
      final institutionName = _requiredString(membership, 'institution_name');
      final institutionActive = membership['institution_active'] == true;
      final status = MembershipStatus.fromDatabaseValue(
        _requiredString(membership, 'status'),
      );
      final invitationExpiresAt = _optionalDateTime(
        membership['invitation_expires_at'],
      );
      final grants = <AccessGrant>[];

      for (final roleValue in _list(membership['roles'], 'roles')) {
        final roleJson = _map(roleValue, 'role');
        final role = AppRole.fromDatabaseKey(_requiredString(roleJson, 'key'));
        if (role == null) continue;
        final permissions = <AppPermission>{};
        for (final permissionValue in _list(
          roleJson['permissions'],
          'permissions',
        )) {
          if (permissionValue is! String) continue;
          final permission = AppPermission.fromDatabaseKey(permissionValue);
          if (permission != null) permissions.add(permission);
        }
        grants.add(
          AccessGrant(
            membershipId: membershipId,
            institutionId: institutionId,
            institutionName: institutionName,
            role: role,
            permissions: Set.unmodifiable(permissions),
          ),
        );
      }

      memberships.add(
        MembershipSummary(
          id: membershipId,
          institutionId: institutionId,
          institutionName: institutionName,
          institutionActive: institutionActive,
          status: status,
          invitationExpiresAt: invitationExpiresAt,
          grants: List.unmodifiable(grants),
        ),
      );
    }

    return IdentityContext(
      userId: userId,
      displayName: displayName,
      profileCompleted: profileCompleted,
      memberships: List.unmodifiable(memberships),
    );
  }

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('Expected $label to be an object.');
  }

  List<Object?> _list(Object? value, String label) {
    if (value == null) return const [];
    if (value is List<Object?>) return value;
    throw FormatException('Expected $label to be a list.');
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected $key to be a non-empty string.');
  }

  String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _optionalDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Expected an ISO-8601 timestamp.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('Expected an ISO-8601 timestamp.');
    }
    return parsed.toUtc();
  }
}
