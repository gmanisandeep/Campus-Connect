import 'package:campus_connect/features/affiliation/data/affiliation_mapper.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AffiliationMapper();

  test('maps institution choices and trims server strings', () {
    final institutions = mapper.institutionsFromJson([
      {'id': 'campus-1', 'name': '  Example College  '},
    ]);

    expect(institutions, hasLength(1));
    expect(institutions.single.id, 'campus-1');
    expect(institutions.single.name, 'Example College');
  });

  test('maps an administrator queue request including audit fields', () {
    final request = mapper.requestFromJson(_requestJson());

    expect(request.status, AffiliationRequestStatus.pending);
    expect(request.programmeId, 'programme-1');
    expect(request.durationMonths, 36);
    expect(request.batchStartYear, 2023);
    expect(request.expectedCompletionYear, 2026);
    expect(request.progressionStatus, StudentProgressionStatus.regular);
    expect(request.verifiedCurrentYear, isNull);
    expect(request.userId, 'student-1');
    expect(request.email, 'student@example.edu');
    expect(request.createdAt, DateTime.utc(2026, 8, 4, 8));
  });

  test('rejects malformed request payloads', () {
    final malformed = _requestJson()..['duration_months'] = 'three years';

    expect(
      () => mapper.requestFromJson(malformed),
      throwsA(isA<FormatException>()),
    );
  });

  test('maps a graduated request without a current academic year', () {
    final request = mapper.requestFromJson(
      _requestJson()..['progression_status'] = 'graduated',
    );

    expect(request.progressionStatus, StudentProgressionStatus.graduated);
    expect(request.verifiedCurrentYear, isNull);
  });
}

Map<String, Object?> _requestJson() => {
  'id': 'request-1',
  'institution_id': 'campus-1',
  'institution_name': 'Example College',
  'official_name': 'Student Name',
  'roll_number': 'CC-42',
  'programme_id': 'programme-1',
  'programme': 'Computer Science',
  'duration_months': 36,
  'batch_start_year': 2023,
  'expected_completion_year': 2026,
  'progression_status': 'regular',
  'verified_current_year': null,
  'status': 'pending',
  'created_at': '2026-08-04T08:00:00Z',
  'updated_at': '2026-08-04T08:00:00Z',
  'user_id': 'student-1',
  'email': 'student@example.edu',
  'decision_note': null,
};
