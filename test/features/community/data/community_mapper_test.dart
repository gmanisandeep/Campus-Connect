import 'package:campus_connect/features/community/data/community_mapper.dart';
import 'package:campus_connect/features/community/domain/community.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CommunityMapper();

  test(
    'maps a provisional college overview with Feed and Faculty contacts',
    () {
      final overview = mapper.overviewFromJson({
        'institution_id': 'campus-1',
        'institution_name': 'Example College',
        'access_state': 'pending_verification',
        'viewer_kind': 'student',
        'feed': [
          {
            'id': 'post-1',
            'title': 'Official update',
            'body': 'College office notice',
            'publisher_name': 'Campus office',
            'published_at': '2026-08-05T01:00:00Z',
          },
        ],
        'contacts': [
          {
            'participant_user_id': 'faculty-1',
            'participant_name': 'Verified Faculty',
            'participant_role': 'Faculty',
            'thread_id': null,
            'last_message': null,
            'last_message_at': null,
          },
        ],
      });

      expect(overview.accessState, CommunityAccessState.pendingVerification);
      expect(overview.viewerKind, CommunityViewerKind.student);
      expect(overview.isProvisional, isTrue);
      expect(overview.feed.single.title, 'Official update');
      expect(overview.contacts.single.participantName, 'Verified Faculty');
    },
  );

  test('maps conversation messages and preserves the server thread', () {
    final conversation = mapper.conversationFromJson({
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
    });

    expect(conversation.threadId, 'thread-1');
    expect(conversation.messages.single.body, 'Hello Faculty');
  });

  test('rejects a malformed Community response', () {
    expect(
      () => mapper.overviewFromJson({'institution_id': 'campus-1'}),
      throwsA(isA<FormatException>()),
    );
  });
}
