import 'package:campus_connect/core/auth/app_role.dart';

enum AttendanceStatus {
  present('Present'),
  absent('Absent'),
  late('Late'),
  excused('Excused');

  const AttendanceStatus(this.label);

  final String label;

  String get databaseKey => name;

  static AttendanceStatus? fromDatabaseValue(String value) => switch (value) {
    'present' => AttendanceStatus.present,
    'absent' => AttendanceStatus.absent,
    'late' => AttendanceStatus.late,
    'excused' => AttendanceStatus.excused,
    _ => null,
  };
}

class RosterStudent {
  const RosterStudent({
    required this.enrolmentId,
    required this.userId,
    required this.displayName,
    this.status,
  });

  final String enrolmentId;
  final String userId;
  final String displayName;
  final AttendanceStatus? status;
}

class ScheduledClass {
  const ScheduledClass({
    required this.timetableEntryId,
    required this.courseOfferingId,
    required this.subjectCode,
    required this.subjectName,
    required this.sectionName,
    required this.startsAt,
    required this.endsAt,
    required this.room,
    required this.attendanceSubmitted,
    required this.roster,
    this.attendanceSessionId,
  });

  final String timetableEntryId;
  final String courseOfferingId;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String startsAt;
  final String endsAt;
  final String room;
  final String? attendanceSessionId;
  final bool attendanceSubmitted;
  final List<RosterStudent> roster;
}

class SubjectAttendanceSummary {
  const SubjectAttendanceSummary({
    required this.courseOfferingId,
    required this.subjectCode,
    required this.subjectName,
    required this.attendedSessions,
    required this.totalSessions,
    required this.excusedSessions,
    required this.percentage,
  });

  final String courseOfferingId;
  final String subjectCode;
  final String subjectName;
  final int attendedSessions;
  final int totalSessions;
  final int excusedSessions;
  final double? percentage;
}

class AcademicDashboard {
  const AcademicDashboard({
    required this.institutionId,
    required this.role,
    required this.date,
    required this.schedule,
    required this.attendanceSummary,
  });

  final String institutionId;
  final AppRole role;
  final DateTime date;
  final List<ScheduledClass> schedule;
  final List<SubjectAttendanceSummary> attendanceSummary;
}

class AttendanceMark {
  const AttendanceMark({required this.studentUserId, required this.status});

  final String studentUserId;
  final AttendanceStatus status;
}
