import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/affiliation/data/supabase_affiliation_repository.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'loads institutions and the current request through scoped RPCs',
    () async {
      final calls = <String>[];
      final repository = _repository((name, parameters) async {
        calls.add(name);
        return switch (name) {
          'list_active_institutions' => [
            {'id': 'campus-1', 'name': 'Example College'},
          ],
          'list_active_programmes' => [
            {
              'id': 'programme-1',
              'institution_id': 'campus-1',
              'name': 'Computer Science',
              'duration_months': 36,
            },
          ],
          'get_my_student_affiliation_request' => null,
          _ => throw StateError('Unexpected RPC $name'),
        };
      });

      final overview = await repository.loadStudentOverview();

      expect(
        calls,
        containsAll(<String>[
          'list_active_institutions',
          'list_active_programmes',
          'get_my_student_affiliation_request',
        ]),
      );
      expect(overview.institutions.single.name, 'Example College');
      expect(overview.programmes.single.durationMonths, 36);
      expect(overview.request, isNull);
    },
  );

  test(
    'trims submission values and verifies returned institution scope',
    () async {
      Map<String, Object?>? sent;
      final repository = _repository((name, parameters) async {
        sent = parameters;
        return _requestJson();
      });

      final request = await repository.submitStudentRequest(
        const StudentAffiliationSubmission(
          institutionId: 'campus-1',
          programmeId: 'programme-1',
          officialName: '  Student Name ',
          rollNumber: ' CC-42 ',
          batchStartYear: 2023,
          expectedCompletionYear: 2026,
          progressionStatus: StudentProgressionStatus.regular,
        ),
      );

      expect(request.status, AffiliationRequestStatus.pending);
      expect(sent?['new_official_name'], 'Student Name');
      expect(sent?['new_roll_number'], 'CC-42');
      expect(sent?['target_programme_id'], 'programme-1');
      expect(sent?['new_batch_start_year'], 2023);
      expect(sent?['new_progression_status'], 'regular');
    },
  );

  test(
    'fails closed when an administrator response escapes campus scope',
    () async {
      final repository = _repository(
        (name, parameters) async => [
          _requestJson()..['institution_id'] = 'another-campus',
        ],
      );

      await expectLater(
        repository.loadPendingRequests('campus-1'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            FailureKind.unexpected,
          ),
        ),
      );
    },
  );

  test('maps database uniqueness errors to a safe conflict', () async {
    final repository = _repository(
      (name, parameters) async => throw const PostgrestException(
        message: 'duplicate key contains private data',
        code: '23505',
      ),
    );

    await expectLater(
      repository.submitStudentRequest(
        const StudentAffiliationSubmission(
          institutionId: 'campus-1',
          programmeId: 'programme-1',
          officialName: 'Student Name',
          rollNumber: 'CC-42',
          batchStartYear: 2023,
          expectedCompletionYear: 2026,
          progressionStatus: StudentProgressionStatus.regular,
        ),
      ),
      throwsA(
        isA<AppFailure>()
            .having((failure) => failure.kind, 'kind', FailureKind.conflict)
            .having(
              (failure) => failure.message,
              'message',
              isNot(contains('private data')),
            ),
      ),
    );
  });
}

SupabaseAffiliationRepository _repository(AffiliationRpcCaller caller) =>
    SupabaseAffiliationRepository(
      const SupabaseGateway.unconfigured(),
      rpcCaller: caller,
    );

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
};
