import 'package:campus_connect/features/affiliation/domain/affiliation.dart';

abstract interface class AffiliationRepository {
  Future<StudentAffiliationOverview> loadStudentOverview();

  Future<StudentAffiliationRequest> submitStudentRequest(
    StudentAffiliationSubmission submission,
  );

  Future<void> cancelStudentRequest(String requestId);

  Future<List<StudentAffiliationRequest>> loadPendingRequests(
    String institutionId,
  );

  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
    int? verifiedCurrentYear,
    String? decisionNote,
  });
}
