import 'dart:async';

import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/social/domain/social.dart';
import 'package:campus_connect/features/social/domain/social_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SupabaseSocialRepository(ref.watch(backendGatewayProvider)),
);

class SupabaseSocialRepository implements SocialRepository {
  const SupabaseSocialRepository(this._gateway);

  final BackendGateway _gateway;
  static const _uuid = Uuid();

  @override
  Future<SocialProfile> ensureProfile() => _run(() async {
    final value = await _rpc('ensure_social_profile');
    return _profile(_map(value));
  });

  @override
  Future<SocialProfile> updateProfile({
    required String username,
    required String bio,
    required bool isPublic,
    required String allowMessageRequests,
    SocialUpload? avatar,
    String? existingAvatarPath,
  }) => _run(() async {
    var avatarPath = existingAvatarPath;
    if (avatar != null) {
      avatarPath = await _upload(
        avatar,
        bucket: 'social-media',
        folder: 'avatars',
      );
    } else if (avatarPath?.startsWith('http') == true) {
      avatarPath = Uri.tryParse(avatarPath!)?.pathSegments.skip(5).join('/');
    }
    final value = await _rpc('update_social_profile', {
      'target_username': username.trim().toLowerCase(),
      'target_bio': bio.trim(),
      'target_avatar_path': avatarPath,
      'target_is_public': isPublic,
      'target_allow_message_requests': allowMessageRequests,
    });
    return _profile(_map(value));
  });

  @override
  Future<List<SocialPost>> loadFeed(SocialFeedMode mode) => _run(() async {
    final value = await _rpc('list_social_feed', {
      'feed_mode': mode.key,
      'page_size': 30,
    });
    return List.unmodifiable(_list(value).map(_post));
  });

  @override
  Future<void> createPost({
    required String body,
    required String visibility,
    required List<SocialUpload> uploads,
    String? institutionId,
    bool official = false,
  }) => _run(() async {
    final media = <Map<String, Object?>>[];
    final uploadedPaths = <String>[];
    try {
      for (var index = 0; index < uploads.length; index++) {
        final upload = uploads[index];
        final path = await _upload(
          upload,
          bucket: 'social-media',
          folder: 'posts',
        );
        uploadedPaths.add(path);
        media.add({
          'storage_path': path,
          'media_kind': upload.kind.name,
          'mime_type': upload.mimeType,
          'alt_text': upload.altText,
          'sort_order': index,
        });
      }
      await _rpc('create_social_post', {
        'target_body': body.trim(),
        'target_visibility': visibility,
        'target_client_post_id': _uuid.v4(),
        'target_institution_id': institutionId,
        'target_is_official': official,
        'target_media': media,
      });
    } on Object {
      if (uploadedPaths.isNotEmpty) {
        try {
          await _gateway.client.storage
              .from('social-media')
              .remove(uploadedPaths);
        } on Object {
          // Preserve the original publishing failure. Storage lifecycle jobs
          // may clean up any object that could not be removed immediately.
        }
      }
      rethrow;
    }
  });

  @override
  Future<bool> toggleLike(String postId) => _run(
    () async =>
        await _rpc('toggle_social_like', {'target_post_id': postId}) as bool,
  );

  @override
  Future<bool> toggleSave(String postId) => _run(
    () async =>
        await _rpc('toggle_social_save', {'target_post_id': postId}) as bool,
  );

  @override
  Future<bool> toggleFollow(String userId) => _run(
    () async =>
        await _rpc('toggle_social_follow', {'target_user_id': userId}) as bool,
  );

  @override
  Future<bool> toggleRepost(String postId, {String? quote}) => _run(
    () async =>
        await _rpc('toggle_social_repost', {
              'target_post_id': postId,
              'target_quote_body': quote,
            })
            as bool,
  );

  @override
  Future<List<SocialComment>> loadComments(String postId) => _run(() async {
    final value = await _rpc('list_social_comments', {
      'target_post_id': postId,
    });
    return List.unmodifiable(_list(value).map(_comment));
  });

  @override
  Future<void> addComment(String postId, String body) => _run(() async {
    await _rpc('add_social_comment', {
      'target_post_id': postId,
      'target_body': body.trim(),
    });
  });

  @override
  Future<SocialInbox> loadInbox() => _run(() async {
    final value = _map(await _rpc('get_social_inbox'));
    return SocialInbox(
      requests: List.unmodifiable(
        _list(value['requests']).map(_messageRequest),
      ),
      threads: List.unmodifiable(_list(value['threads']).map(_threadSummary)),
    );
  });

  @override
  Future<List<SocialMessage>> loadThread(String threadId) => _run(() async {
    final value = await _rpc('get_social_thread', {
      'target_thread_id': threadId,
    });
    return List.unmodifiable(_list(value).map(_message));
  });

  @override
  Future<String> sendMessageRequest(String userId, String openingMessage) =>
      _run(
        () async => (await _rpc('send_social_message_request', {
          'target_recipient_user_id': userId,
          'target_opening_message': openingMessage.trim(),
        })).toString(),
      );

  @override
  Future<String?> respondMessageRequest(String requestId, bool accept) =>
      _run(() async {
        final value = await _rpc('respond_social_message_request', {
          'target_request_id': requestId,
          'target_accept': accept,
        });
        return value?.toString();
      });

  @override
  Future<void> sendMessage(String threadId, String body) => _run(() async {
    await _rpc('send_social_message', {
      'target_thread_id': threadId,
      'target_body': body.trim(),
      'target_client_message_id': _uuid.v4(),
    });
  });

  @override
  Future<List<InstitutionDirectoryEntry>> searchInstitutions(String query) =>
      _run(() async {
        final value = await _rpc('list_public_institutions', {
          'search_text': query.trim().isEmpty ? null : query.trim(),
          'result_limit': 150,
        });
        return List.unmodifiable(_list(value).map(_institution));
      });

  @override
  Future<String> uploadPrivateDocument(SocialUpload upload) =>
      _run(() => _upload(upload, bucket: 'claim-documents', folder: 'claims'));

  @override
  Future<String> submitInstitutionClaim(InstitutionClaimInput input) => _run(
    () async => (await _rpc('submit_institution_claim', {
      'target_institution_id': input.institutionId,
      'target_applicant_name': input.applicantName.trim(),
      'target_designation': input.designation.trim(),
      'target_employee_id': input.employeeId.trim(),
      'target_official_email': input.officialEmail.trim().toLowerCase(),
      'target_official_phone': input.officialPhone.trim(),
      'target_authorization_document_path': input.authorizationDocumentPath,
      'target_notes': input.notes?.trim(),
    })).toString(),
  );

  @override
  Future<String> submitFacultyRegistration(FacultyRegistrationInput input) =>
      _run(
        () async => (await _rpc('submit_faculty_registration', {
          'target_institution_id': input.institutionId,
          'target_employee_id': input.employeeId.trim(),
          'target_department': input.department.trim(),
          'target_designation': input.designation.trim(),
          'target_official_email': input.officialEmail.trim().toLowerCase(),
        })).toString(),
      );

  @override
  Future<List<InstitutionClaimReview>> loadInstitutionClaimsForReview() =>
      _run(() async {
        final value = await _rpc('list_institution_claims_for_review');
        return List.unmodifiable(_list(value).map(_institutionClaimReview));
      });

  @override
  Future<void> reviewInstitutionClaim(
    String claimId,
    String decision, {
    String? notes,
  }) => _run(() async {
    await _rpc('review_institution_claim', {
      'target_claim_id': claimId,
      'target_decision': decision,
      'target_reviewer_notes': notes,
    });
  });

  @override
  Future<List<FacultyRegistrationReview>> loadFacultyRegistrationsForReview(
    String institutionId,
  ) => _run(() async {
    final value = await _rpc('list_faculty_registrations_for_review', {
      'target_institution_id': institutionId,
    });
    return List.unmodifiable(_list(value).map(_facultyRegistrationReview));
  });

  @override
  Future<void> reviewFacultyRegistration(
    String registrationId,
    String decision, {
    String? notes,
  }) => _run(() async {
    await _rpc('review_faculty_registration', {
      'target_registration_id': registrationId,
      'target_decision': decision,
      'target_notes': notes,
    });
  });

  @override
  Future<void> reportPost(String postId, String reason, {String? details}) =>
      _run(() async {
        await _rpc('report_social_content', {
          'target_reason': reason,
          'target_details': details,
          'target_post_id': postId,
        });
      });

  @override
  Future<void> blockUser(String userId) => _run(() async {
    await _rpc('block_social_user', {
      'target_user_id': userId,
      'target_block': true,
    });
  });

  Future<Object?> _rpc(String name, [Map<String, Object?>? params]) =>
      _gateway.client.rpc<Object?>(name, params: params);

  Future<String> _upload(
    SocialUpload upload, {
    required String bucket,
    required String folder,
  }) async {
    final userId = _gateway.client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppFailure(
        kind: FailureKind.authentication,
        message: 'Sign in again to upload.',
      );
    }
    final safeName = upload.name.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    final path = '$userId/$folder/${_uuid.v4()}-$safeName';
    await _gateway.client.storage
        .from(bucket)
        .uploadBinary(
          path,
          upload.bytes,
          fileOptions: FileOptions(contentType: upload.mimeType, upsert: false),
        );
    return path;
  }

  SocialPost _post(Map<String, dynamic> value) => SocialPost(
    id: _string(value, 'id'),
    authorUserId: _string(value, 'author_user_id'),
    authorName: _string(value, 'author_name'),
    username: value['username'] as String?,
    avatarPath: _publicUrl(value['avatar_path'] as String?),
    body: value['body'] as String? ?? '',
    publishedAt: DateTime.parse(_string(value, 'published_at')).toLocal(),
    media: List.unmodifiable(_list(value['media']).map((item) => _media(item))),
    likeCount: _int(value['like_count']),
    commentCount: _int(value['comment_count']),
    repostCount: _int(value['repost_count']),
    likedByViewer: value['liked_by_viewer'] == true,
    savedByViewer: value['saved_by_viewer'] == true,
    isOfficial: value['is_official'] == true,
    isCollegeVerified: value['author_verified'] == true,
    institutionName: value['institution_name'] as String?,
  );

  SocialMedia _media(Map<String, dynamic> value) => SocialMedia(
    path: _publicUrl(_string(value, 'storage_path'))!,
    kind: SocialMediaKind.values.byName(_string(value, 'media_kind')),
    mimeType: _string(value, 'mime_type'),
    altText: value['alt_text'] as String? ?? '',
  );

  SocialComment _comment(Map<String, dynamic> value) => SocialComment(
    id: _string(value, 'id'),
    authorUserId: _string(value, 'author_user_id'),
    authorName: _string(value, 'author_name'),
    username: value['username'] as String?,
    body: _string(value, 'body'),
    createdAt: DateTime.parse(_string(value, 'created_at')).toLocal(),
    parentCommentId: value['parent_comment_id'] as String?,
  );

  SocialProfile _profile(Map<String, dynamic> value) => SocialProfile(
    userId: _string(value, 'user_id'),
    username: _string(value, 'username'),
    bio: value['bio'] as String? ?? '',
    avatarPath: _publicUrl(value['avatar_path'] as String?),
    isPublic: value['is_public'] != false,
    allowMessageRequests:
        value['allow_message_requests'] as String? ?? 'everyone',
  );

  MessageRequest _messageRequest(Map<String, dynamic> value) => MessageRequest(
    id: _string(value, 'id'),
    senderUserId: _string(value, 'sender_user_id'),
    senderName: _string(value, 'sender_name'),
    openingMessage: _string(value, 'opening_message'),
    createdAt: DateTime.parse(_string(value, 'created_at')).toLocal(),
  );

  SocialThreadSummary _threadSummary(Map<String, dynamic> value) =>
      SocialThreadSummary(
        id: _string(value, 'id'),
        participantUserId: _string(value, 'participant_user_id'),
        participantName: _string(value, 'participant_name'),
        lastMessage: value['last_message'] as String?,
        lastMessageAt: DateTime.parse(
          _string(value, 'last_message_at'),
        ).toLocal(),
      );

  SocialMessage _message(Map<String, dynamic> value) => SocialMessage(
    id: _string(value, 'id'),
    senderUserId: _string(value, 'sender_user_id'),
    body: value['body'] as String? ?? '',
    sentAt: DateTime.parse(_string(value, 'sent_at')).toLocal(),
    attachmentPath: _publicUrl(value['attachment_path'] as String?),
    attachmentKind: value['attachment_kind'] as String?,
    sharedPostId: value['shared_post_id'] as String?,
  );

  InstitutionDirectoryEntry _institution(Map<String, dynamic> value) =>
      InstitutionDirectoryEntry(
        id: _string(value, 'id'),
        name: _string(value, 'name'),
        registrationStatus: _string(value, 'registration_status'),
        city: value['city'] as String?,
        district: value['district'] as String?,
        aisheCode: value['aishe_code'] as String?,
        officialWebsite: value['official_website'] as String?,
      );

  InstitutionClaimReview _institutionClaimReview(Map<String, dynamic> value) =>
      InstitutionClaimReview(
        id: _string(value, 'id'),
        institutionName: _string(value, 'institution_name'),
        applicantName: _string(value, 'applicant_name'),
        designation: _string(value, 'designation'),
        employeeId: _string(value, 'employee_id'),
        officialEmail: _string(value, 'official_email'),
        officialPhone: _string(value, 'official_phone'),
        documentPath: _string(value, 'authorization_document_path'),
        notes: value['notes'] as String?,
        submittedAt: DateTime.parse(_string(value, 'submitted_at')).toLocal(),
      );

  FacultyRegistrationReview _facultyRegistrationReview(
    Map<String, dynamic> value,
  ) => FacultyRegistrationReview(
    id: _string(value, 'id'),
    institutionId: _string(value, 'institution_id'),
    applicantName: _string(value, 'applicant_name'),
    employeeId: _string(value, 'employee_id'),
    department: _string(value, 'department'),
    designation: _string(value, 'designation'),
    officialEmail: _string(value, 'official_email'),
    submittedAt: DateTime.parse(_string(value, 'submitted_at')).toLocal(),
  );

  String? _publicUrl(String? path) => path == null || path.isEmpty
      ? null
      : path.startsWith('http')
      ? path
      : _gateway.client.storage.from('social-media').getPublicUrl(path);

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 30));
    } on AppFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw AppFailure(
        kind: error.code == '42501'
            ? FailureKind.authorization
            : FailureKind.server,
        message: error.message.isEmpty
            ? 'The social service is unavailable.'
            : error.message,
        cause: error,
      );
    } on StorageException catch (error) {
      throw AppFailure(
        kind: FailureKind.server,
        message: 'The attachment could not be uploaded.',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw AppFailure(
        kind: FailureKind.timeout,
        message: 'The request timed out. Try again.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        kind: FailureKind.connectivity,
        message: 'CampusConnect could not reach the server.',
        cause: error,
      );
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value case final Map<Object?, Object?> value) {
    return value.cast<String, dynamic>();
  }
  throw const FormatException('Expected a JSON object.');
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value == null) return const [];
  if (value case final List<Object?> values) {
    return values.map(_map).toList(growable: false);
  }
  throw const FormatException('Expected a JSON list.');
}

String _string(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is String && result.isNotEmpty) return result;
  throw FormatException('Missing $key.');
}

int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;
