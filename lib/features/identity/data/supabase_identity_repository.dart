import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/storage/secure_supabase_local_storage.dart';
import 'package:campus_connect/features/identity/data/identity_context_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseIdentityRepository implements IdentityRepository {
  const SupabaseIdentityRepository(
    this._gateway,
    this._sessionGate, {
    IdentityContextMapper mapper = const IdentityContextMapper(),
    Stream<AuthState>? authStateChanges,
  }) : _mapper = mapper,
       _authStateChanges = authStateChanges;

  static const _authCallback = 'campusconnect://auth-callback';

  final BackendGateway _gateway;
  final AuthSessionGate _sessionGate;
  final IdentityContextMapper _mapper;
  final Stream<AuthState>? _authStateChanges;

  SupabaseClient get _client => _gateway.client;
  Stream<AuthState> get _authStates =>
      _authStateChanges ?? _client.auth.onAuthStateChange;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<IdentityAuthEvent> get authEvents =>
      _authStates.asyncExpand((state) async* {
        final session = state.session;
        final userId = session?.user.id;
        final classification = switch (state.event) {
          AuthChangeEvent.signedIn => AuthSessionClassification.authenticated,
          AuthChangeEvent.passwordRecovery =>
            AuthSessionClassification.passwordRecovery,
          _ => null,
        };

        if (classification != null) {
          // GoTrue has already replaced currentSession at this point. Remove
          // any authority derived from the previous session before durable
          // classification can yield or fail.
          yield IdentityAuthEvent(
            type: IdentityAuthEventType.sessionTransition,
            userId: userId,
          );
          try {
            if (session == null) {
              throw AuthSessionMissingException();
            }
            await _sessionGate.classify(session, classification);
          } on Object {
            yield IdentityAuthEvent(
              type: IdentityAuthEventType.sessionInvalid,
              userId: userId,
            );
            return;
          }
        }

        if (state.event == AuthChangeEvent.signedOut) {
          yield const IdentityAuthEvent(
            type: IdentityAuthEventType.sessionTransition,
          );
          try {
            // Supabase's local-storage callback is asynchronous. Await the
            // security gate directly so signed-out cannot be published while
            // a trusted persisted classification remains on disk.
            await _sessionGate.clear();
          } on Object {
            yield const IdentityAuthEvent(
              type: IdentityAuthEventType.sessionInvalid,
            );
            return;
          }
        }

        final type = switch (state.event) {
          AuthChangeEvent.passwordRecovery =>
            IdentityAuthEventType.passwordRecovery,
          AuthChangeEvent.signedOut => IdentityAuthEventType.signedOut,
          _ => IdentityAuthEventType.sessionChanged,
        };
        yield IdentityAuthEvent(type: type, userId: userId);
      });

  @override
  Future<RestoredIdentitySession> restoreSession() async {
    try {
      var session = _client.auth.currentSession;
      if (session == null) return RestoredIdentitySession.none;
      if (session.isExpired) {
        session = (await _client.auth.refreshSession()).session;
      }
      if (session == null) return RestoredIdentitySession.none;
      final classification = await _sessionGate.classificationFor(session);
      return switch (classification) {
        AuthSessionClassification.authenticated =>
          RestoredIdentitySession.authenticated,
        AuthSessionClassification.passwordRecovery =>
          RestoredIdentitySession.passwordRecovery,
        AuthSessionClassification.unclassified =>
          RestoredIdentitySession.unclassified,
      };
    } on AuthRetryableFetchException {
      rethrow;
    } on AuthSessionMissingException {
      return RestoredIdentitySession.none;
    } on AuthInvalidJwtException {
      return RestoredIdentitySession.none;
    } on AuthApiException catch (error) {
      if (const {'400', '401', '403'}.contains(error.statusCode)) {
        return RestoredIdentitySession.none;
      }
      rethrow;
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run(
        () async {
          final response = await _client.auth.signInWithPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );
          if (response.session == null || response.user == null) {
            throw const AppFailure(
              kind: FailureKind.authentication,
              message: 'Unable to sign in with those credentials.',
            );
          }
          await _sessionGate.classify(
            response.session!,
            AuthSessionClassification.authenticated,
          );
        },
        message: 'Unable to sign in with those credentials.',
        authFailure: true,
      );

  @override
  Future<AccountCreationResult> signUp({
    required String email,
    required String password,
  }) => _run(
    () async {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: _authCallback,
      );
      if (response.user == null) {
        throw const AppFailure(
          kind: FailureKind.authentication,
          message: 'Unable to create your account right now.',
        );
      }
      final session = response.session;
      if (session == null) {
        return const AccountCreationResult(confirmationRequired: true);
      }
      await _sessionGate.classify(
        session,
        AuthSessionClassification.authenticated,
      );
      return const AccountCreationResult(confirmationRequired: false);
    },
    message: 'Unable to create your account right now.',
    authFailure: true,
  );

  @override
  Future<void> requestPasswordReset(String email) => _run(
    () => _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: _authCallback,
    ),
    message: 'Unable to send reset instructions right now.',
  );

  @override
  Future<void> updatePassword(String password) => _run(
    () async {
      final email = _client.auth.currentUser?.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        throw const AppFailure(
          kind: FailureKind.authentication,
          message: 'The recovery session is no longer available.',
        );
      }

      await _client.auth.updateUser(UserAttributes(password: password));
      // A recovery JWT remains OTP-authenticated after updateUser. Revoke
      // and clear it before obtaining a new password-authenticated session.
      await _clearSessionDurably(suppressRemoteFailure: false);
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null || response.user == null) {
        throw const AppFailure(
          kind: FailureKind.authentication,
          message: 'Unable to sign in with the updated password.',
        );
      }
      await _sessionGate.classify(
        response.session!,
        AuthSessionClassification.authenticated,
      );
    },
    message: 'Unable to update the password right now.',
    authFailure: true,
  );

  @override
  Future<IdentityContext> loadMyIdentityContext() => _run(() async {
    final Object? response = await _client.rpc<Object?>(
      'get_my_identity_context',
    );
    return _mapper.fromJson(response);
  }, message: 'Unable to load your campus access right now.');

  @override
  Future<IdentityContext> acceptMyInvitation({
    required String membershipId,
    required String displayName,
  }) => _run(() async {
    final Object? response = await _client.rpc<Object?>(
      'accept_my_invitation',
      params: {
        'target_membership_id': membershipId,
        'new_display_name': displayName.trim(),
      },
    );
    return _mapper.fromJson(response);
  }, message: 'Unable to accept this invitation.');

  @override
  Future<IdentityContext> completeMyProfile(String displayName) =>
      _run(() async {
        final Object? response = await _client.rpc<Object?>(
          'complete_my_profile',
          params: {'new_display_name': displayName.trim()},
        );
        return _mapper.fromJson(response);
      }, message: 'Unable to complete your profile.');

  @override
  Future<void> signOut() => _run(
    _signOutDurably,
    message: 'Unable to sign out right now.',
    authFailure: true,
  );

  @override
  Future<void> discardSession() =>
      _clearSessionDurably(suppressRemoteFailure: true);

  Future<void> _signOutDurably() =>
      _clearSessionDurably(suppressRemoteFailure: false);

  Future<void> _clearSessionDurably({
    required bool suppressRemoteFailure,
  }) async {
    // Calling GoTrue's async signOut removes its in-memory session before its
    // first await. Start it first, then independently await our secure gate.
    Object? remoteError;
    StackTrace? remoteStackTrace;
    final remoteSignOut = _client.auth.signOut().then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        // Attach immediately: revocation may fail while secure clearing is
        // blocked, and the original Future must never surface as unhandled.
        remoteError = error;
        remoteStackTrace = stackTrace;
      },
    );
    Object? clearError;
    StackTrace? clearStackTrace;
    try {
      await _sessionGate.clear();
    } on Object catch (error, stackTrace) {
      clearError = error;
      clearStackTrace = stackTrace;
    }

    await remoteSignOut;

    if (clearError != null) {
      Error.throwWithStackTrace(clearError, clearStackTrace!);
    }
    if (!suppressRemoteFailure && remoteError != null) {
      Error.throwWithStackTrace(remoteError!, remoteStackTrace!);
    }
  }

  Future<T> _run<T>(
    Future<T> Function() operation, {
    required String message,
    bool authFailure = false,
  }) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AppFailure(
        kind: authFailure ? FailureKind.authentication : FailureKind.server,
        message: message,
        cause: error,
      );
    } on PostgrestException catch (error) {
      final forbidden = error.code == '42501';
      throw AppFailure(
        kind: forbidden ? FailureKind.authorization : FailureKind.server,
        message: forbidden ? 'You are not allowed to do that.' : message,
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppFailure(
        kind: FailureKind.unexpected,
        message: 'The server returned an invalid identity response.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        kind: FailureKind.connectivity,
        message: message,
        cause: error,
      );
    }
  }
}
