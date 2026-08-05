enum AffiliationRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  unknown;

  static AffiliationRequestStatus fromDatabaseValue(String value) =>
      switch (value) {
        'pending' => AffiliationRequestStatus.pending,
        'approved' => AffiliationRequestStatus.approved,
        'rejected' => AffiliationRequestStatus.rejected,
        'cancelled' => AffiliationRequestStatus.cancelled,
        _ => AffiliationRequestStatus.unknown,
      };
}

enum StudentProgressionStatus {
  regular,
  onLeave,
  repeating,
  lateralEntry,
  graduated,
  unknown;

  static StudentProgressionStatus fromDatabaseValue(String? value) =>
      switch (value) {
        'regular' => StudentProgressionStatus.regular,
        'on_leave' => StudentProgressionStatus.onLeave,
        'repeating' => StudentProgressionStatus.repeating,
        'lateral_entry' => StudentProgressionStatus.lateralEntry,
        'graduated' => StudentProgressionStatus.graduated,
        _ => StudentProgressionStatus.unknown,
      };

  String get databaseValue => switch (this) {
    StudentProgressionStatus.regular => 'regular',
    StudentProgressionStatus.onLeave => 'on_leave',
    StudentProgressionStatus.repeating => 'repeating',
    StudentProgressionStatus.lateralEntry => 'lateral_entry',
    StudentProgressionStatus.graduated => 'graduated',
    StudentProgressionStatus.unknown => 'unknown',
  };

  String get label => switch (this) {
    StudentProgressionStatus.regular => 'Regular progression',
    StudentProgressionStatus.onLeave => 'Gap or approved leave',
    StudentProgressionStatus.repeating => 'Repeating an academic year',
    StudentProgressionStatus.lateralEntry => 'Lateral entry',
    StudentProgressionStatus.graduated => 'Graduated',
    StudentProgressionStatus.unknown => 'Not provided',
  };
}

class InstitutionChoice {
  const InstitutionChoice({required this.id, required this.name});

  final String id;
  final String name;
}

class ProgrammeChoice {
  const ProgrammeChoice({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.durationMonths,
  });

  final String id;
  final String institutionId;
  final String name;
  final int durationMonths;

  int get maximumAcademicYear => (durationMonths / 12).ceil();

  String get durationLabel {
    final years = durationMonths ~/ 12;
    final months = durationMonths % 12;
    if (months == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years ${years == 1 ? 'year' : 'years'} $months months';
  }
}

class StudentAffiliationRequest {
  const StudentAffiliationRequest({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.officialName,
    required this.rollNumber,
    required this.programmeId,
    required this.programme,
    required this.durationMonths,
    required this.batchStartYear,
    required this.expectedCompletionYear,
    required this.progressionStatus,
    required this.verifiedCurrentYear,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.email,
    this.decisionNote,
  });

  final String id;
  final String institutionId;
  final String institutionName;
  final String officialName;
  final String rollNumber;
  final String? programmeId;
  final String programme;
  final int? durationMonths;
  final int? batchStartYear;
  final int? expectedCompletionYear;
  final StudentProgressionStatus progressionStatus;
  final int? verifiedCurrentYear;
  final AffiliationRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final String? email;
  final String? decisionNote;
}

class StudentAffiliationOverview {
  const StudentAffiliationOverview({
    required this.institutions,
    required this.programmes,
    required this.request,
  });

  final List<InstitutionChoice> institutions;
  final List<ProgrammeChoice> programmes;
  final StudentAffiliationRequest? request;
}

class StudentAffiliationSubmission {
  const StudentAffiliationSubmission({
    required this.institutionId,
    required this.programmeId,
    required this.officialName,
    required this.rollNumber,
    required this.batchStartYear,
    required this.expectedCompletionYear,
    required this.progressionStatus,
  });

  final String institutionId;
  final String programmeId;
  final String officialName;
  final String rollNumber;
  final int batchStartYear;
  final int expectedCompletionYear;
  final StudentProgressionStatus progressionStatus;
}
