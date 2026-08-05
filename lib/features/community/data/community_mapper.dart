import 'package:campus_connect/features/community/domain/community.dart';

class CommunityMapper {
  const CommunityMapper();

  CommunityOverview overviewFromJson(Object? value) {
    final map = _map(value, 'community overview');
    return CommunityOverview(
      institutionId: _string(map, 'institution_id'),
      institutionName: _string(map, 'institution_name'),
      accessState: switch (map['access_state']) {
        'pending_verification' => CommunityAccessState.pendingVerification,
        'verified' => CommunityAccessState.verified,
        _ => CommunityAccessState.unknown,
      },
      viewerKind: switch (map['viewer_kind']) {
        'student' => CommunityViewerKind.student,
        'faculty' => CommunityViewerKind.faculty,
        _ => CommunityViewerKind.unknown,
      },
      feed: List.unmodifiable(
        _list(map['feed'], 'community feed').map(_feedPost),
      ),
      contacts: List.unmodifiable(
        _list(map['contacts'], 'community contacts').map(_contact),
      ),
    );
  }

  CommunityConversation conversationFromJson(Object? value) {
    final map = _map(value, 'conversation');
    final threadId = map['thread_id'];
    return CommunityConversation(
      threadId: threadId == null
          ? null
          : _requiredString(threadId, 'thread_id'),
      messages: List.unmodifiable(messagesFromJson(map['messages'])),
    );
  }

  List<CommunityMessage> messagesFromJson(Object? value) => [
    for (final item in _list(value, 'messages')) _message(item),
  ];

  CommunityFeedPost _feedPost(Object? value) {
    final map = _map(value, 'feed post');
    return CommunityFeedPost(
      id: _string(map, 'id'),
      title: _string(map, 'title'),
      body: _string(map, 'body'),
      publisherName: _string(map, 'publisher_name'),
      publishedAt: _dateTime(map, 'published_at'),
    );
  }

  CommunityContact _contact(Object? value) {
    final map = _map(value, 'contact');
    return CommunityContact(
      participantUserId: _string(map, 'participant_user_id'),
      participantName: _string(map, 'participant_name'),
      participantRole: _string(map, 'participant_role'),
      threadId: _optionalString(map['thread_id']),
      lastMessage: _optionalString(map['last_message']),
      lastMessageAt: _optionalDateTime(map['last_message_at']),
    );
  }

  CommunityMessage _message(Object? value) {
    final map = _map(value, 'message');
    return CommunityMessage(
      id: _string(map, 'id'),
      threadId: _string(map, 'thread_id'),
      senderUserId: _string(map, 'sender_user_id'),
      body: _string(map, 'body'),
      sentAt: _dateTime(map, 'sent_at'),
    );
  }

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw FormatException('Expected $label object.');
  }

  List<Object?> _list(Object? value, String label) {
    if (value is List) return value.cast<Object?>();
    throw FormatException('Expected $label list.');
  }

  String _string(Map<String, Object?> map, String key) =>
      _requiredString(map[key], key);

  String _requiredString(Object? value, String key) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected $key string.');
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    return _requiredString(value, 'optional value');
  }

  DateTime _dateTime(Map<String, Object?> map, String key) {
    final parsed = _optionalDateTime(map[key]);
    if (parsed == null) throw FormatException('Expected $key timestamp.');
    return parsed;
  }

  DateTime? _optionalDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Expected timestamp.');
    return DateTime.tryParse(value)?.toLocal() ??
        (throw const FormatException('Expected ISO timestamp.'));
  }
}
