import 'dart:async';

import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/academics/data/academic_dashboard_mapper.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/academic_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AcademicRpcCaller =
    Future<Object?> Function(
      String functionName,
      Map<String, Object?> parameters,
    );

class SupabaseAcademicRepository implements AcademicRepository {
  const SupabaseAcademicRepository(
    this._gateway, {
    AcademicDashboardMapper mapper = const AcademicDashboardMapper(),
    AcademicRpcCaller? rpcCaller,
  }) : _mapper = mapper,
       _rpcCaller = rpcCaller;

  final BackendGateway _gateway;
  final AcademicDashboardMapper _mapper;
  final AcademicRpcCaller? _rpcCaller;

  @override
  Future<AcademicDashboard> loadDashboard({
    required String institutionId,
    required AppRole role,
    required DateTime? targetDate,
  }) {
    if (role != AppRole.student && role != AppRole.faculty) {
      throw const AppFailure(
        kind: FailureKind.authorization,
        message: 'Academic access is not available for this role.',
      );
    }
    return _run(() async {
      final response = await _rpc('get_my_academic_dashboard', {
        'target_institution_id': institutionId,
        'target_role': role.databaseKey,
        'target_date': targetDate == null ? null : _formatDate(targetDate),
      });
      final dashboard = _mapper.fromJson(response);
      _verifyScope(
        dashboard,
        institutionId: institutionId,
        role: role,
        date: targetDate,
      );
      return dashboard;
    }, serverMessage: 'Unable to load academics right now.');
  }

  @override
  Future<AcademicDashboard> submitAttendance({
    required String institutionId,
    required String courseOfferingId,
    required String timetableEntryId,
    required DateTime sessionDate,
    required List<AttendanceMark> marks,
    required String requestId,
  }) => _run(() async {
    final response = await _rpc('submit_attendance', {
      'target_institution_id': institutionId,
      'target_course_offering_id': courseOfferingId,
      'target_timetable_entry_id': timetableEntryId,
      'target_session_date': _formatDate(sessionDate),
      'attendance_payload': [
        for (final mark in marks)
          {
            'student_user_id': mark.studentUserId,
            'status': mark.status.databaseKey,
          },
      ],
      'request_id': requestId,
    });
    final dashboard = _mapper.fromJson(response);
    _verifyScope(
      dashboard,
      institutionId: institutionId,
      role: AppRole.faculty,
      date: sessionDate,
    );
    _verifyAttendanceConfirmation(
      dashboard,
      courseOfferingId: courseOfferingId,
      timetableEntryId: timetableEntryId,
      marks: marks,
    );
    return dashboard;
  }, serverMessage: 'Unable to submit attendance right now.');

  Future<Object?> _rpc(String functionName, Map<String, Object?> parameters) {
    final caller = _rpcCaller;
    if (caller != null) return caller(functionName, parameters);
    return _gateway.client.rpc<Object?>(functionName, params: parameters);
  }

  Future<T> _run<T>(
    Future<T> Function() operation, {
    required String serverMessage,
  }) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppFailure(
        kind: FailureKind.timeout,
        message: 'The request timed out. Try again.',
        cause: error,
      );
    } on AuthException catch (error) {
      throw AppFailure(
        kind: FailureKind.authentication,
        message: 'Your session is no longer available. Sign in again.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      final (kind, message) = switch (error.code) {
        '42501' => (
          FailureKind.authorization,
          'You are not allowed to do that.',
        ),
        '23505' => (
          FailureKind.conflict,
          'Attendance has already been submitted for this class.',
        ),
        '22023' || '23514' => (
          FailureKind.validation,
          'Check the attendance entries and try again.',
        ),
        'PGRST116' => (
          FailureKind.notFound,
          'That academic record is no longer available.',
        ),
        _ => (FailureKind.server, serverMessage),
      };
      throw AppFailure(kind: kind, message: message, cause: error);
    } on FormatException catch (error) {
      throw AppFailure(
        kind: FailureKind.unexpected,
        message: 'The server returned an invalid academic response.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        kind: FailureKind.connectivity,
        message: serverMessage,
        cause: error,
      );
    }
  }

  void _verifyScope(
    AcademicDashboard dashboard, {
    required String institutionId,
    required AppRole role,
    required DateTime? date,
  }) {
    if (dashboard.institutionId != institutionId ||
        dashboard.role != role ||
        (date != null && !_sameDate(dashboard.date, date))) {
      throw const FormatException('Academic response scope did not match.');
    }
  }

  void _verifyAttendanceConfirmation(
    AcademicDashboard dashboard, {
    required String courseOfferingId,
    required String timetableEntryId,
    required List<AttendanceMark> marks,
  }) {
    ScheduledClass? confirmedClass;
    for (final scheduledClass in dashboard.schedule) {
      if (scheduledClass.courseOfferingId == courseOfferingId &&
          scheduledClass.timetableEntryId == timetableEntryId) {
        if (confirmedClass != null) {
          throw const FormatException(
            'Attendance confirmation class must be unique.',
          );
        }
        confirmedClass = scheduledClass;
      }
    }
    if (confirmedClass == null ||
        !confirmedClass.attendanceSubmitted ||
        confirmedClass.attendanceSessionId == null ||
        confirmedClass.attendanceSessionId!.isEmpty ||
        confirmedClass.roster.length != marks.length) {
      throw const FormatException(
        'Attendance was not confirmed by the server.',
      );
    }

    final expected = {
      for (final mark in marks) mark.studentUserId: mark.status,
    };
    if (expected.length != marks.length) {
      throw const FormatException('Attendance marks must be unique.');
    }
    for (final student in confirmedClass.roster) {
      if (student.status == null ||
          expected[student.userId] != student.status) {
        throw const FormatException(
          'Attendance confirmation did not match the submitted marks.',
        );
      }
    }
  }
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
