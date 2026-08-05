import 'dart:async';

import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/affiliation/data/affiliation_mapper.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AffiliationRpcCaller =
    Future<Object?> Function(
      String functionName,
      Map<String, Object?> parameters,
    );

class SupabaseAffiliationRepository implements AffiliationRepository {
  const SupabaseAffiliationRepository(
    this._gateway, {
    AffiliationMapper mapper = const AffiliationMapper(),
    AffiliationRpcCaller? rpcCaller,
  }) : _mapper = mapper,
       _rpcCaller = rpcCaller;

  final BackendGateway _gateway;
  final AffiliationMapper _mapper;
  final AffiliationRpcCaller? _rpcCaller;

  @override
  Future<StudentAffiliationOverview> loadStudentOverview() => _run(() async {
    final results = await Future.wait<Object?>([
      _rpc('list_active_institutions'),
      _rpc('list_active_programmes'),
      _rpc('get_my_student_affiliation_request'),
    ]);
    return StudentAffiliationOverview(
      institutions: List.unmodifiable(_mapper.institutionsFromJson(results[0])),
      programmes: List.unmodifiable(_mapper.programmesFromJson(results[1])),
      request: _mapper.optionalRequestFromJson(results[2]),
    );
  }, serverMessage: 'Unable to load college verification right now.');

  @override
  Future<StudentAffiliationRequest> submitStudentRequest(
    StudentAffiliationSubmission submission,
  ) => _run(() async {
    final response = await _rpc('submit_student_affiliation_request', {
      'target_institution_id': submission.institutionId,
      'target_programme_id': submission.programmeId,
      'new_official_name': submission.officialName.trim(),
      'new_roll_number': submission.rollNumber.trim(),
      'new_batch_start_year': submission.batchStartYear,
      'new_expected_completion_year': submission.expectedCompletionYear,
      'new_progression_status': submission.progressionStatus.databaseValue,
    });
    final request = _mapper.requestFromJson(response);
    if (request.institutionId != submission.institutionId ||
        request.status != AffiliationRequestStatus.pending) {
      throw const FormatException('Request scope did not match submission.');
    }
    return request;
  }, serverMessage: 'Unable to submit this verification request.');

  @override
  Future<void> cancelStudentRequest(String requestId) => _run(
    () => _rpc('cancel_my_student_affiliation_request', {
      'target_request_id': requestId,
    }),
    serverMessage: 'Unable to cancel this verification request.',
  );

  @override
  Future<List<StudentAffiliationRequest>> loadPendingRequests(
    String institutionId,
  ) => _run(() async {
    final response = await _rpc('list_pending_student_affiliation_requests', {
      'target_institution_id': institutionId,
    });
    final requests = _mapper.requestsFromJson(response);
    if (requests.any(
      (request) =>
          request.institutionId != institutionId ||
          request.status != AffiliationRequestStatus.pending,
    )) {
      throw const FormatException('Request list escaped its campus scope.');
    }
    return List.unmodifiable(requests);
  }, serverMessage: 'Unable to load student verification requests.');

  @override
  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
    int? verifiedCurrentYear,
    String? decisionNote,
  }) => _run(
    () => _rpc('review_student_affiliation_request', {
      'target_request_id': requestId,
      'approve_request': approve,
      'new_verified_current_year': verifiedCurrentYear,
      'new_decision_note': decisionNote?.trim(),
    }),
    serverMessage: 'Unable to record this verification decision.',
  );

  Future<Object?> _rpc(
    String functionName, [
    Map<String, Object?> parameters = const {},
  ]) {
    final caller = _rpcCaller;
    if (caller != null) return caller(functionName, parameters);
    return _gateway.client.rpc<Object?>(
      functionName,
      params: parameters.isEmpty ? null : parameters,
    );
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
          'A matching college request is already pending.',
        ),
        '22023' || '23514' => (
          FailureKind.validation,
          'Check the submitted details and try again.',
        ),
        'P0002' || 'PGRST116' => (
          FailureKind.notFound,
          'That college or request is no longer available.',
        ),
        _ => (FailureKind.server, serverMessage),
      };
      throw AppFailure(kind: kind, message: message, cause: error);
    } on FormatException catch (error) {
      throw AppFailure(
        kind: FailureKind.unexpected,
        message: 'The server returned an invalid verification response.',
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
}
