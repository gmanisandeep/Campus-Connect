import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/features/community/data/supabase_community_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('overview passes the active institution to the secured RPC', () async {
    String? function;
    Map<String, Object?>? parameters;
    final repository = SupabaseCommunityRepository(
      const _UnusedGateway(),
      rpcCaller: (name, values) async {
        function = name;
        parameters = values;
        return _overviewJson();
      },
    );

    final overview = await repository.loadOverview('campus-1');

    expect(function, 'get_my_community_overview');
    expect(parameters, {'target_institution_id': 'campus-1'});
    expect(overview.institutionName, 'Example College');
  });

  test(
    'send carries an idempotency key and returns confirmed messages',
    () async {
      Map<String, Object?>? parameters;
      final repository = SupabaseCommunityRepository(
        const _UnusedGateway(),
        rpcCaller: (name, values) async {
          expect(name, 'send_faculty_contact_message');
          parameters = values;
          return {
            'thread_id': 'thread-1',
            'messages': [
              {
                'id': 'message-1',
                'thread_id': 'thread-1',
                'sender_user_id': 'student-1',
                'body': 'Hello Faculty',
                'sent_at': '2026-08-05T01:02:00Z',
              },
            ],
          };
        },
      );

      final conversation = await repository.sendMessage(
        institutionId: 'campus-1',
        threadId: null,
        facultyUserId: 'faculty-1',
        clientMessageId: 'request-1',
        body: ' Hello Faculty ',
      );

      expect(parameters?['client_message_id'], 'request-1');
      expect(parameters?['new_body'], 'Hello Faculty');
      expect(conversation.messages.single.body, 'Hello Faculty');
    },
  );
}

Map<String, Object?> _overviewJson() => {
  'institution_id': 'campus-1',
  'institution_name': 'Example College',
  'access_state': 'pending_verification',
  'viewer_kind': 'student',
  'feed': const [],
  'contacts': const [],
};

class _UnusedGateway implements BackendGateway {
  const _UnusedGateway();

  @override
  bool get isConfigured => false;

  @override
  SupabaseClient get client => throw StateError('Not used by this test.');
}
