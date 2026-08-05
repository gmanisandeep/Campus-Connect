import 'dart:typed_data';

enum SocialFeedMode { forYou, following, college, saved }

extension SocialFeedModeKey on SocialFeedMode {
  String get key => switch (this) {
    SocialFeedMode.forYou => 'for_you',
    SocialFeedMode.following => 'following',
    SocialFeedMode.college => 'college',
    SocialFeedMode.saved => 'saved',
  };
}

enum SocialMediaKind { image, video, document }

class SocialMedia {
  const SocialMedia({
    required this.path,
    required this.kind,
    required this.mimeType,
    required this.altText,
  });

  final String path;
  final SocialMediaKind kind;
  final String mimeType;
  final String altText;
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.username,
    required this.body,
    required this.publishedAt,
    required this.media,
    required this.likeCount,
    required this.commentCount,
    required this.repostCount,
    required this.likedByViewer,
    required this.savedByViewer,
    required this.isOfficial,
    this.avatarPath,
    this.institutionName,
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String? username;
  final String? avatarPath;
  final String body;
  final DateTime publishedAt;
  final List<SocialMedia> media;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final bool likedByViewer;
  final bool savedByViewer;
  final bool isOfficial;
  final String? institutionName;

  SocialPost copyWith({
    int? likeCount,
    bool? likedByViewer,
    bool? savedByViewer,
    int? commentCount,
    int? repostCount,
  }) => SocialPost(
    id: id,
    authorUserId: authorUserId,
    authorName: authorName,
    username: username,
    avatarPath: avatarPath,
    body: body,
    publishedAt: publishedAt,
    media: media,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    repostCount: repostCount ?? this.repostCount,
    likedByViewer: likedByViewer ?? this.likedByViewer,
    savedByViewer: savedByViewer ?? this.savedByViewer,
    isOfficial: isOfficial,
    institutionName: institutionName,
  );
}

class SocialComment {
  const SocialComment({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.username,
    this.parentCommentId,
  });

  final String id;
  final String authorUserId;
  final String authorName;
  final String? username;
  final String body;
  final DateTime createdAt;
  final String? parentCommentId;
}

class SocialUpload {
  const SocialUpload({
    required this.name,
    required this.bytes,
    required this.kind,
    required this.mimeType,
    this.altText = '',
  });

  final String name;
  final Uint8List bytes;
  final SocialMediaKind kind;
  final String mimeType;
  final String altText;
}

class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.username,
    required this.bio,
    required this.isPublic,
    required this.allowMessageRequests,
    this.avatarPath,
  });

  final String userId;
  final String username;
  final String bio;
  final String? avatarPath;
  final bool isPublic;
  final String allowMessageRequests;
}

class MessageRequest {
  const MessageRequest({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.openingMessage,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String senderName;
  final String openingMessage;
  final DateTime createdAt;
}

class SocialThreadSummary {
  const SocialThreadSummary({
    required this.id,
    required this.participantUserId,
    required this.participantName,
    required this.lastMessageAt,
    this.lastMessage,
  });

  final String id;
  final String participantUserId;
  final String participantName;
  final String? lastMessage;
  final DateTime lastMessageAt;
}

class SocialInbox {
  const SocialInbox({required this.requests, required this.threads});

  final List<MessageRequest> requests;
  final List<SocialThreadSummary> threads;
}

class SocialMessage {
  const SocialMessage({
    required this.id,
    required this.senderUserId,
    required this.body,
    required this.sentAt,
    this.attachmentPath,
    this.attachmentKind,
    this.sharedPostId,
  });

  final String id;
  final String senderUserId;
  final String body;
  final DateTime sentAt;
  final String? attachmentPath;
  final String? attachmentKind;
  final String? sharedPostId;
}

class InstitutionDirectoryEntry {
  const InstitutionDirectoryEntry({
    required this.id,
    required this.name,
    required this.registrationStatus,
    this.city,
    this.district,
    this.aisheCode,
    this.officialWebsite,
  });

  final String id;
  final String name;
  final String registrationStatus;
  final String? city;
  final String? district;
  final String? aisheCode;
  final String? officialWebsite;

  bool get isVerified => registrationStatus == 'verified';
}

class InstitutionClaimInput {
  const InstitutionClaimInput({
    required this.institutionId,
    required this.applicantName,
    required this.designation,
    required this.employeeId,
    required this.officialEmail,
    required this.officialPhone,
    required this.authorizationDocumentPath,
    this.notes,
  });

  final String institutionId;
  final String applicantName;
  final String designation;
  final String employeeId;
  final String officialEmail;
  final String officialPhone;
  final String authorizationDocumentPath;
  final String? notes;
}

class FacultyRegistrationInput {
  const FacultyRegistrationInput({
    required this.institutionId,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.officialEmail,
  });

  final String institutionId;
  final String employeeId;
  final String department;
  final String designation;
  final String officialEmail;
}

class InstitutionClaimReview {
  const InstitutionClaimReview({
    required this.id,
    required this.institutionName,
    required this.applicantName,
    required this.designation,
    required this.employeeId,
    required this.officialEmail,
    required this.officialPhone,
    required this.documentPath,
    required this.submittedAt,
    this.notes,
  });
  final String id;
  final String institutionName;
  final String applicantName;
  final String designation;
  final String employeeId;
  final String officialEmail;
  final String officialPhone;
  final String documentPath;
  final String? notes;
  final DateTime submittedAt;
}

class FacultyRegistrationReview {
  const FacultyRegistrationReview({
    required this.id,
    required this.institutionId,
    required this.applicantName,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.officialEmail,
    required this.submittedAt,
  });
  final String id;
  final String institutionId;
  final String applicantName;
  final String employeeId;
  final String department;
  final String designation;
  final String officialEmail;
  final DateTime submittedAt;
}
