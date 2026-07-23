import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';

abstract interface class AcademicRepository {
  Future<AcademicDashboard> loadDashboard({
    required String institutionId,
    required AppRole role,
    required DateTime? targetDate,
  });

  Future<AcademicDashboard> submitAttendance({
    required String institutionId,
    required String courseOfferingId,
    required String timetableEntryId,
    required DateTime sessionDate,
    required List<AttendanceMark> marks,
    required String requestId,
  });
}
