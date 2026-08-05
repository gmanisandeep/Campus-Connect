import 'package:campus_connect/features/social/domain/social.dart';

abstract interface class SocialRepository {
  Future<SocialProfile> ensureProfile();
  Future<List<SocialPost>> loadFeed(SocialFeedMode mode);
  Future<void> createPost({
    required String body,
    required String visibility,
    required List<SocialUpload> uploads,
    String? institutionId,
    bool official = false,
  });
  Future<bool> toggleLike(String postId);
  Future<bool> toggleSave(String postId);
  Future<bool> toggleFollow(String userId);
  Future<bool> toggleRepost(String postId, {String? quote});
  Future<List<SocialComment>> loadComments(String postId);
  Future<void> addComment(String postId, String body);
  Future<SocialInbox> loadInbox();
  Future<List<SocialMessage>> loadThread(String threadId);
  Future<String> sendMessageRequest(String userId, String openingMessage);
  Future<String?> respondMessageRequest(String requestId, bool accept);
  Future<void> sendMessage(String threadId, String body);
  Future<List<InstitutionDirectoryEntry>> searchInstitutions(String query);
  Future<String> uploadPrivateDocument(SocialUpload upload);
  Future<String> submitInstitutionClaim(InstitutionClaimInput input);
  Future<String> submitFacultyRegistration(FacultyRegistrationInput input);
  Future<List<InstitutionClaimReview>> loadInstitutionClaimsForReview();
  Future<void> reviewInstitutionClaim(
    String claimId,
    String decision, {
    String? notes,
  });
  Future<List<FacultyRegistrationReview>> loadFacultyRegistrationsForReview(
    String institutionId,
  );
  Future<void> reviewFacultyRegistration(
    String registrationId,
    String decision, {
    String? notes,
  });
  Future<void> reportPost(String postId, String reason, {String? details});
  Future<void> blockUser(String userId);
}
