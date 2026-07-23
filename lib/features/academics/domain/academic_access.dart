import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';

bool canViewAcademics(AccessGrant? grant) => switch (grant?.role) {
  AppRole.student => grant!.permissions.contains(
    AppPermission.attendanceReadOwn,
  ),
  AppRole.faculty => grant!.permissions.contains(AppPermission.rosterRead),
  _ => false,
};

bool canSubmitAttendance(AccessGrant? grant) =>
    grant?.role == AppRole.faculty &&
    grant!.permissions.contains(AppPermission.attendanceRecord);
