import 'package:campus_connect/features/community/domain/community.dart';

abstract interface class CommunityRepository {
  Future<CommunityOverview> loadOverview(String? institutionId);

  Future<CommunityConversation> loadConversation(String threadId);

  Future<CommunityConversation> sendMessage({
    required String institutionId,
    required String? threadId,
    required String? facultyUserId,
    required String clientMessageId,
    required String body,
  });
}
