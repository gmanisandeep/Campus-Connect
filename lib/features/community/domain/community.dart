enum CommunityAccessState { pendingVerification, verified, unknown }

enum CommunityViewerKind { student, faculty, unknown }

class CommunityFeedPost {
  const CommunityFeedPost({
    required this.id,
    required this.title,
    required this.body,
    required this.publisherName,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final String publisherName;
  final DateTime publishedAt;
}

class CommunityContact {
  const CommunityContact({
    required this.participantUserId,
    required this.participantName,
    required this.participantRole,
    this.threadId,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String participantUserId;
  final String participantName;
  final String participantRole;
  final String? threadId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
}

class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String threadId;
  final String senderUserId;
  final String body;
  final DateTime sentAt;
}

class CommunityConversation {
  const CommunityConversation({required this.threadId, required this.messages});

  final String? threadId;
  final List<CommunityMessage> messages;
}

class CommunityOverview {
  const CommunityOverview({
    required this.institutionId,
    required this.institutionName,
    required this.accessState,
    required this.viewerKind,
    required this.feed,
    required this.contacts,
  });

  final String institutionId;
  final String institutionName;
  final CommunityAccessState accessState;
  final CommunityViewerKind viewerKind;
  final List<CommunityFeedPost> feed;
  final List<CommunityContact> contacts;

  bool get isProvisional =>
      accessState == CommunityAccessState.pendingVerification;
}
