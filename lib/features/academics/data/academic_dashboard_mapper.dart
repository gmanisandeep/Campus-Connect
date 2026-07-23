import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';

class AcademicDashboardMapper {
  const AcademicDashboardMapper();

  AcademicDashboard fromJson(Object? value) {
    final root = _map(value, 'academic dashboard');
    final roleKey = _requiredString(root, 'role');
    final role = AppRole.fromDatabaseKey(roleKey);
    if (role != AppRole.student && role != AppRole.faculty) {
      throw const FormatException('Expected a supported academic role.');
    }

    final schedule = <ScheduledClass>[];
    for (final item in _list(root['schedule'], 'schedule')) {
      schedule.add(_scheduledClass(item));
    }

    final summaries = <SubjectAttendanceSummary>[];
    for (final item in _list(
      root['attendance_summary'],
      'attendance_summary',
    )) {
      summaries.add(_attendanceSummary(item));
    }

    return AcademicDashboard(
      institutionId: _requiredString(root, 'institution_id'),
      role: role!,
      date: _date(root['date']),
      schedule: List.unmodifiable(schedule),
      attendanceSummary: List.unmodifiable(summaries),
    );
  }

  ScheduledClass _scheduledClass(Object? value) {
    final item = _map(value, 'scheduled class');
    final roster = <RosterStudent>[];
    final studentIds = <String>{};
    for (final rosterValue in _list(item['roster'], 'roster')) {
      final student = _rosterStudent(rosterValue);
      if (!studentIds.add(student.userId)) {
        throw const FormatException('Roster students must be unique.');
      }
      roster.add(student);
    }

    return ScheduledClass(
      timetableEntryId: _requiredString(item, 'timetable_entry_id'),
      courseOfferingId: _requiredString(item, 'course_offering_id'),
      subjectCode: _requiredString(item, 'subject_code'),
      subjectName: _requiredString(item, 'subject_name'),
      sectionName: _requiredString(item, 'section_name'),
      startsAt: _time(item['starts_at'], 'starts_at'),
      endsAt: _time(item['ends_at'], 'ends_at'),
      room: _requiredString(item, 'room'),
      attendanceSessionId: _optionalString(item['attendance_session_id']),
      attendanceSubmitted: _requiredBool(item, 'attendance_submitted'),
      roster: List.unmodifiable(roster),
    );
  }

  RosterStudent _rosterStudent(Object? value) {
    final item = _map(value, 'roster student');
    final statusValue = item['status'];
    AttendanceStatus? status;
    if (statusValue != null) {
      if (statusValue is! String) {
        throw const FormatException('Expected status to be a string.');
      }
      status = AttendanceStatus.fromDatabaseValue(statusValue);
      if (status == null) {
        throw FormatException('Unknown attendance status: $statusValue.');
      }
    }
    return RosterStudent(
      enrolmentId: _requiredString(item, 'enrolment_id'),
      userId: _requiredString(item, 'student_user_id'),
      displayName: _requiredString(item, 'display_name'),
      status: status,
    );
  }

  SubjectAttendanceSummary _attendanceSummary(Object? value) {
    final item = _map(value, 'attendance summary');
    final percentage = _optionalNumber(item['percentage'], 'percentage');
    if (percentage != null && (percentage < 0 || percentage > 100)) {
      throw const FormatException('Percentage must be between 0 and 100.');
    }
    return SubjectAttendanceSummary(
      courseOfferingId: _requiredString(item, 'course_offering_id'),
      subjectCode: _requiredString(item, 'subject_code'),
      subjectName: _requiredString(item, 'subject_name'),
      attendedSessions: _nonNegativeInt(item, 'attended_sessions'),
      totalSessions: _nonNegativeInt(item, 'total_sessions'),
      excusedSessions: _nonNegativeInt(item, 'excused_sessions'),
      percentage: percentage,
    );
  }

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('Expected $label to be an object.');
  }

  List<Object?> _list(Object? value, String label) {
    if (value is List<Object?>) return value;
    throw FormatException('Expected $label to be a list.');
  }

  String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('Expected $key to be a non-empty string.');
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw const FormatException('Expected a nullable non-empty string.');
  }

  bool _requiredBool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw FormatException('Expected $key to be a boolean.');
  }

  int _nonNegativeInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int && value >= 0) return value;
    throw FormatException('Expected $key to be a non-negative integer.');
  }

  double? _optionalNumber(Object? value, String label) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('Expected $label to be numeric or null.');
  }

  DateTime _date(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Expected an ISO calendar date.');
    }
    final parts = value.split('-').map(int.parse).toList(growable: false);
    final date = DateTime(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2]) {
      throw const FormatException('Expected a valid calendar date.');
    }
    return date;
  }

  String _time(Object? value, String label) {
    if (value is String &&
        RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      return value;
    }
    throw FormatException('Expected $label in HH:mm format.');
  }
}
