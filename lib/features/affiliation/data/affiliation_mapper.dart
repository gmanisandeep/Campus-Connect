import 'package:campus_connect/features/affiliation/domain/affiliation.dart';

class AffiliationMapper {
  const AffiliationMapper();

  List<InstitutionChoice> institutionsFromJson(Object? value) => [
    for (final item in _list(value, 'institutions'))
      InstitutionChoice(
        id: _requiredString(_map(item, 'institution'), 'id'),
        name: _requiredString(_map(item, 'institution'), 'name'),
      ),
  ];

  List<ProgrammeChoice> programmesFromJson(Object? value) => [
    for (final item in _list(value, 'programmes'))
      ProgrammeChoice(
        id: _requiredString(_map(item, 'programme'), 'id'),
        institutionId: _requiredString(
          _map(item, 'programme'),
          'institution_id',
        ),
        name: _requiredString(_map(item, 'programme'), 'name'),
        durationMonths: _requiredInt(
          _map(item, 'programme'),
          'duration_months',
        ),
      ),
  ];

  StudentAffiliationRequest? optionalRequestFromJson(Object? value) =>
      value == null ? null : requestFromJson(value);

  StudentAffiliationRequest requestFromJson(Object? value) {
    final json = _map(value, 'affiliation request');
    return StudentAffiliationRequest(
      id: _requiredString(json, 'id'),
      institutionId: _requiredString(json, 'institution_id'),
      institutionName: _requiredString(json, 'institution_name'),
      officialName: _requiredString(json, 'official_name'),
      rollNumber: _requiredString(json, 'roll_number'),
      programmeId: _optionalString(json['programme_id']),
      programme: _requiredString(json, 'programme'),
      durationMonths: _optionalInt(json['duration_months']),
      batchStartYear: _optionalInt(json['batch_start_year']),
      expectedCompletionYear: _optionalInt(json['expected_completion_year']),
      progressionStatus: StudentProgressionStatus.fromDatabaseValue(
        _optionalString(json['progression_status']),
      ),
      verifiedCurrentYear: _optionalInt(json['verified_current_year']),
      status: AffiliationRequestStatus.fromDatabaseValue(
        _requiredString(json, 'status'),
      ),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
      userId: _optionalString(json['user_id']),
      email: _optionalString(json['email']),
      decisionNote: _optionalString(json['decision_note']),
    );
  }

  List<StudentAffiliationRequest> requestsFromJson(Object? value) => [
    for (final item in _list(value, 'affiliation requests'))
      requestFromJson(item),
  ];

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('Expected $label to be an object.');
  }

  List<Object?> _list(Object? value, String label) {
    if (value is List<Object?>) return value;
    throw FormatException('Expected $label to be a list.');
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('Expected $key to be a non-empty string.');
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Expected an optional string.');
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected $key to be an integer.');
  }

  int? _optionalInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected an optional integer.');
  }

  DateTime _requiredDateTime(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    throw FormatException('Expected $key to be an ISO-8601 timestamp.');
  }
}
