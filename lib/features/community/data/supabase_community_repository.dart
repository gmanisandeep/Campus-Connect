import 'dart:async';

import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/community/data/community_mapper.dart';
import 'package:campus_connect/features/community/domain/community.dart';
import 'package:campus_connect/features/community/domain/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef CommunityRpcCaller =
    Future<Object?> Function(
      String functionName,
      Map<String, Object?> parameters,
    );

class SupabaseCommunityRepository implements CommunityRepository {
  const SupabaseCommunityRepository(
    this._gateway, {
    CommunityMapper mapper = const CommunityMapper(),
    CommunityRpcCaller? rpcCaller,
  }) : _mapper = mapper,
       _rpcCaller = rpcCaller;

  final BackendGateway _gateway;
  final CommunityMapper _mapper;
  final CommunityRpcCaller? _rpcCaller;

  @override
  Future<CommunityOverview> loadOverview(String? institutionId) => _run(
    () async => _mapper.overviewFromJson(
      await _rpc('get_my_community_overview', {
        'target_institution_id': institutionId,
      }),
    ),
    serverMessage: 'Unable to load Community right now.',
  );

  @override
  Future<CommunityConversation> loadConversation(String threadId) => _run(
    () async => CommunityConversation(
      threadId: threadId,
      messages: List.unmodifiable(
        _mapper.messagesFromJson(
          await _rpc('list_faculty_contact_messages', {
            'target_thread_id': threadId,
          }),
        ),
      ),
    ),
    serverMessage: 'Unable to load this conversation.',
  );

  @override
  Future<CommunityConversation> sendMessage({
    required String institutionId,
    required String? threadId,
    required String? facultyUserId,
    required String clientMessageId,
    required String body,
  }) => _run(
    () async => _mapper.conversationFromJson(
      await _rpc('send_faculty_contact_message', {
        'target_institution_id': institutionId,
        'target_thread_id': threadId,
        'target_faculty_user_id': facultyUserId,
        'client_message_id': clientMessageId,
        'new_body': body.trim(),
      }),
    ),
    serverMessage: 'Unable to send this message.',
  );

  Future<Object?> _rpc(String functionName, Map<String, Object?> parameters) {
    final caller = _rpcCaller;
    if (caller != null) return caller(functionName, parameters);
    return _gateway.client.rpc<Object?>(functionName, params: parameters);
  }

  Future<T> _run<T>(
    Future<T> Function() operation, {
    required String serverMessage,
  }) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppFailure(
        kind: FailureKind.timeout,
        message: 'The request timed out. Try again.',
        cause: error,
      );
    } on AuthException catch (error) {
      throw AppFailure(
        kind: FailureKind.authentication,
        message: 'Your session is no longer available. Sign in again.',
        cause: error,
      );
    } on PostgrestException catch (error) {
      final (kind, message) = switch (error.code) {
        '42501' => (
          FailureKind.authorization,
          'Community access is no longer available for this account.',
        ),
        '22023' ||
        '23514' => (FailureKind.validation, 'Check the message and try again.'),
        'P0002' || 'PGRST116' => (
          FailureKind.notFound,
          'That campus conversation is no longer available.',
        ),
        _ => (FailureKind.server, serverMessage),
      };
      throw AppFailure(kind: kind, message: message, cause: error);
    } on FormatException catch (error) {
      throw AppFailure(
        kind: FailureKind.unexpected,
        message: 'The server returned an invalid Community response.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        kind: FailureKind.connectivity,
        message: serverMessage,
        cause: error,
      );
    }
  }
}
