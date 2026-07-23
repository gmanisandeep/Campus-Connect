import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/academics/data/supabase_academic_repository.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'today load sends null and trusts the institution-local server date',
    () async {
      String? calledFunction;
      Map<String, Object?>? calledParameters;
      final repository = SupabaseAcademicRepository(
        const SupabaseGateway.unconfigured(),
        rpcCaller: (functionName, parameters) async {
          calledFunction = functionName;
          calledParameters = parameters;
          return _dashboardPayload(role: 'student', date: '2026-07-21');
        },
      );

      final result = await repository.loadDashboard(
        institutionId: 'institution-1',
        role: AppRole.student,
        targetDate: null,
      );

      expect(calledFunction, 'get_my_academic_dashboard');
      expect(calledParameters, {
        'target_institution_id': 'institution-1',
        'target_role': 'student',
        'target_date': null,
      });
      expect(result.role, AppRole.student);
      expect(result.date, DateTime(2026, 7, 21));
    },
  );

  test('an explicit target date is formatted and scope checked', () async {
    Map<String, Object?>? calledParameters;
    final repository = SupabaseAcademicRepository(
      const SupabaseGateway.unconfigured(),
      rpcCaller: (_, parameters) async {
        calledParameters = parameters;
        return _dashboardPayload(role: 'student');
      },
    );

    await repository.loadDashboard(
      institutionId: 'institution-1',
      role: AppRole.student,
      targetDate: DateTime(2026, 7, 20, 23, 30),
    );

    expect(calledParameters?['target_date'], '2026-07-20');

    final mismatchedRepository = SupabaseAcademicRepository(
      const SupabaseGateway.unconfigured(),
      rpcCaller: (_, __) async =>
          _dashboardPayload(role: 'student', date: '2026-07-21'),
    );
    await expectLater(
      mismatchedRepository.loadDashboard(
        institutionId: 'institution-1',
        role: AppRole.student,
        targetDate: DateTime(2026, 7, 20),
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.unexpected,
        ),
      ),
    );
  });

  test('submits the complete attendance RPC payload', () async {
    String? calledFunction;
    Map<String, Object?>? calledParameters;
    final repository = SupabaseAcademicRepository(
      const SupabaseGateway.unconfigured(),
      rpcCaller: (functionName, parameters) async {
        calledFunction = functionName;
        calledParameters = parameters;
        return _attendanceConfirmationPayload();
      },
    );

    final result = await repository.submitAttendance(
      institutionId: 'institution-1',
      courseOfferingId: 'offering-1',
      timetableEntryId: 'entry-1',
      sessionDate: DateTime(2026, 7, 20),
      marks: const [
        AttendanceMark(
          studentUserId: 'student-1',
          status: AttendanceStatus.present,
        ),
        AttendanceMark(
          studentUserId: 'student-2',
          status: AttendanceStatus.absent,
        ),
      ],
      requestId: 'request-1',
    );

    final confirmedClass = result.schedule.single;
    expect(confirmedClass.attendanceSubmitted, isTrue);
    expect(confirmedClass.attendanceSessionId, 'session-1');
    expect(confirmedClass.roster.map((student) => student.status), [
      AttendanceStatus.present,
      AttendanceStatus.absent,
    ]);
    expect(calledFunction, 'submit_attendance');
    expect(calledParameters, {
      'target_institution_id': 'institution-1',
      'target_course_offering_id': 'offering-1',
      'target_timetable_entry_id': 'entry-1',
      'target_session_date': '2026-07-20',
      'attendance_payload': [
        {'student_user_id': 'student-1', 'status': 'present'},
        {'student_user_id': 'student-2', 'status': 'absent'},
      ],
      'request_id': 'request-1',
    });
  });

  group('attendance confirmation verification', () {
    final scenarios = <({String name, Map<String, Object?> payload})>[
      (
        name: 'missing submitted class',
        payload: _dashboardPayload(role: 'faculty'),
      ),
      (
        name: 'missing attendance session',
        payload: _attendanceConfirmationPayload(attendanceSessionId: null),
      ),
      (
        name: 'class not marked submitted',
        payload: _attendanceConfirmationPayload(attendanceSubmitted: false),
      ),
      (
        name: 'wrong course offering id',
        payload: _attendanceConfirmationPayload(
          courseOfferingId: 'another-offering',
        ),
      ),
      (
        name: 'wrong timetable entry id',
        payload: _attendanceConfirmationPayload(
          timetableEntryId: 'another-entry',
        ),
      ),
      (
        name: 'wrong attendance status',
        payload: _attendanceConfirmationPayload(
          roster: _confirmationRoster(firstStatus: 'absent'),
        ),
      ),
      (
        name: 'wrong roster membership',
        payload: _attendanceConfirmationPayload(
          roster: _confirmationRoster(secondUserId: 'student-3'),
        ),
      ),
      (
        name: 'incomplete roster',
        payload: _attendanceConfirmationPayload(
          roster: _confirmationRoster().take(1).toList(),
        ),
      ),
    ];

    for (final scenario in scenarios) {
      test('rejects ${scenario.name}', () async {
        final repository = SupabaseAcademicRepository(
          const SupabaseGateway.unconfigured(),
          rpcCaller: (_, __) async => scenario.payload,
        );

        await expectLater(
          repository.submitAttendance(
            institutionId: 'institution-1',
            courseOfferingId: 'offering-1',
            timetableEntryId: 'entry-1',
            sessionDate: DateTime(2026, 7, 20),
            marks: const [
              AttendanceMark(
                studentUserId: 'student-1',
                status: AttendanceStatus.present,
              ),
              AttendanceMark(
                studentUserId: 'student-2',
                status: AttendanceStatus.absent,
              ),
            ],
            requestId: 'request-1',
          ),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.kind,
              'kind',
              FailureKind.unexpected,
            ),
          ),
        );
      });
    }
  });

  test(
    'maps database authorization and conflict details to safe failures',
    () async {
      Future<void> expectFailure(String code, FailureKind expectedKind) async {
        final repository = SupabaseAcademicRepository(
          const SupabaseGateway.unconfigured(),
          rpcCaller: (_, __) async => throw PostgrestException(
            message: 'sensitive database detail',
            code: code,
          ),
        );

        await expectLater(
          repository.loadDashboard(
            institutionId: 'institution-1',
            role: AppRole.student,
            targetDate: null,
          ),
          throwsA(
            isA<AppFailure>()
                .having((failure) => failure.kind, 'kind', expectedKind)
                .having(
                  (failure) => failure.message,
                  'safe message',
                  isNot(contains('sensitive')),
                ),
          ),
        );
      }

      await expectFailure('42501', FailureKind.authorization);
      await expectFailure('23505', FailureKind.conflict);
    },
  );

  test('rejects a response from a different tenant', () async {
    final payload = _dashboardPayload(role: 'student')
      ..['institution_id'] = 'another-institution';
    final repository = SupabaseAcademicRepository(
      const SupabaseGateway.unconfigured(),
      rpcCaller: (_, __) async => payload,
    );

    await expectLater(
      repository.loadDashboard(
        institutionId: 'institution-1',
        role: AppRole.student,
        targetDate: null,
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.kind,
          'kind',
          FailureKind.unexpected,
        ),
      ),
    );
  });
}

Map<String, Object?> _dashboardPayload({
  required String role,
  String date = '2026-07-20',
}) => {
  'institution_id': 'institution-1',
  'role': role,
  'date': date,
  'schedule': <Object?>[],
  'attendance_summary': <Object?>[],
};

Map<String, Object?> _attendanceConfirmationPayload({
  String courseOfferingId = 'offering-1',
  String timetableEntryId = 'entry-1',
  Object? attendanceSessionId = 'session-1',
  bool attendanceSubmitted = true,
  List<Object?>? roster,
}) => {
  'institution_id': 'institution-1',
  'role': 'faculty',
  'date': '2026-07-20',
  'schedule': <Object?>[
    <String, Object?>{
      'timetable_entry_id': timetableEntryId,
      'course_offering_id': courseOfferingId,
      'subject_code': 'CS701',
      'subject_name': 'Distributed Systems',
      'section_name': 'A',
      'starts_at': '09:00',
      'ends_at': '10:00',
      'room': 'R-101',
      'attendance_session_id': attendanceSessionId,
      'attendance_submitted': attendanceSubmitted,
      'roster': roster ?? _confirmationRoster(),
    },
  ],
  'attendance_summary': <Object?>[],
};

List<Object?> _confirmationRoster({
  String firstUserId = 'student-1',
  String secondUserId = 'student-2',
  String firstStatus = 'present',
  String secondStatus = 'absent',
}) => [
  <String, Object?>{
    'enrolment_id': 'enrolment-1',
    'student_user_id': firstUserId,
    'display_name': 'Student One',
    'status': firstStatus,
  },
  <String, Object?>{
    'enrolment_id': 'enrolment-2',
    'student_user_id': secondUserId,
    'display_name': 'Student Two',
    'status': secondStatus,
  },
];
