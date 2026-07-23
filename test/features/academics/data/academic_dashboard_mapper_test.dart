import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/features/academics/data/academic_dashboard_mapper.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AcademicDashboardMapper();

  test('maps a faculty schedule, roster, and submitted statuses', () {
    final dashboard = mapper.fromJson(_dashboardPayload());

    expect(dashboard.institutionId, 'institution-1');
    expect(dashboard.role, AppRole.faculty);
    expect(dashboard.date, DateTime(2026, 7, 20));
    expect(dashboard.schedule, hasLength(1));
    final scheduledClass = dashboard.schedule.single;
    expect(scheduledClass.startsAt, '09:00');
    expect(scheduledClass.attendanceSubmitted, isTrue);
    expect(scheduledClass.attendanceSessionId, 'session-1');
    expect(scheduledClass.roster, hasLength(2));
    expect(scheduledClass.roster.map((student) => student.status), [
      AttendanceStatus.present,
      AttendanceStatus.late,
    ]);
  });

  test('maps student summaries with numeric and nullable percentages', () {
    final payload = _dashboardPayload(role: 'student')
      ..['schedule'] = <Object?>[]
      ..['attendance_summary'] = [
        {
          'course_offering_id': 'offering-1',
          'subject_code': 'CS701',
          'subject_name': 'Distributed Systems',
          'attended_sessions': 7,
          'total_sessions': 10,
          'excused_sessions': 1,
          'percentage': 70,
        },
        {
          'course_offering_id': 'offering-2',
          'subject_code': 'CS702',
          'subject_name': 'Mobile Application Development',
          'attended_sessions': 0,
          'total_sessions': 0,
          'excused_sessions': 0,
          'percentage': null,
        },
      ];

    final dashboard = mapper.fromJson(payload);

    expect(dashboard.role, AppRole.student);
    expect(dashboard.attendanceSummary, hasLength(2));
    expect(dashboard.attendanceSummary.first.percentage, 70.0);
    expect(dashboard.attendanceSummary.last.percentage, isNull);
  });

  test('rejects malformed times, statuses, and unsupported roles', () {
    final invalidTime = _dashboardPayload();
    final schedule = invalidTime['schedule']! as List<Object?>;
    (schedule.single as Map<String, Object?>)['starts_at'] = '9 AM';
    expect(() => mapper.fromJson(invalidTime), throwsFormatException);

    final invalidStatus = _dashboardPayload();
    final invalidSchedule = invalidStatus['schedule']! as List<Object?>;
    final scheduledClass = invalidSchedule.single as Map<String, Object?>;
    final roster = scheduledClass['roster']! as List<Object?>;
    (roster.first as Map<String, Object?>)['status'] = 'unknown';
    expect(() => mapper.fromJson(invalidStatus), throwsFormatException);

    final invalidRole = _dashboardPayload()..['role'] = 'administrator';
    expect(() => mapper.fromJson(invalidRole), throwsFormatException);
  });
}

Map<String, Object?> _dashboardPayload({String role = 'faculty'}) => {
  'institution_id': 'institution-1',
  'role': role,
  'date': '2026-07-20',
  'schedule': [
    {
      'timetable_entry_id': 'entry-1',
      'course_offering_id': 'offering-1',
      'subject_code': 'CS701',
      'subject_name': 'Distributed Systems',
      'section_name': 'CSE A',
      'starts_at': '09:00',
      'ends_at': '10:00',
      'room': 'A-101',
      'attendance_session_id': 'session-1',
      'attendance_submitted': true,
      'roster': [
        {
          'enrolment_id': 'enrolment-1',
          'student_user_id': 'student-1',
          'display_name': 'Ada Student',
          'status': 'present',
        },
        {
          'enrolment_id': 'enrolment-2',
          'student_user_id': 'student-2',
          'display_name': 'Lin Student',
          'status': 'late',
        },
      ],
    },
  ],
  'attendance_summary': <Object?>[],
};
