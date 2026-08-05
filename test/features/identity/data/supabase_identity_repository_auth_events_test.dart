import 'dart:async';
import 'dart:convert';

import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/storage/secure_supabase_local_storage.dart';
import 'package:campus_connect/features/identity/data/supabase_identity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late _MockBackendGateway gateway;
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late _ControllableSessionGate sessionGate;
  late StreamController<AuthState> authStates;

  setUp(() {
    gateway = _MockBackendGateway();
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    sessionGate = _ControllableSessionGate();
    authStates = StreamController<AuthState>.broadcast();

    when(() => gateway.client).thenReturn(client);
    when(() => client.auth).thenReturn(auth);
    when(() => auth.onAuthStateChange).thenAnswer((_) => authStates.stream);
  });

  tearDown(() => authStates.close());

  test(
    'recovery transition is emitted before durable classification finishes',
    () async {
      final classification = Completer<void>();
      sessionGate.classificationBarrier = classification;
      final repository = SupabaseIdentityRepository(gateway, sessionGate);
      final received = <IdentityAuthEvent>[];
      final errors = <Object>[];
      final subscription = repository.authEvents.listen(
        received.add,
        onError: errors.add,
      );
      addTearDown(subscription.cancel);
      addTearDown(() {
        if (!classification.isCompleted) classification.complete();
      });

      authStates.add(
        AuthState(AuthChangeEvent.passwordRecovery, _session('recovery-user')),
      );
      await _waitUntil(() => sessionGate.classifyCalls == 1);

      expect(errors, isEmpty);
      expect(received.map((event) => event.type), [
        IdentityAuthEventType.sessionTransition,
      ]);
      expect(received.single.userId, 'recovery-user');
      expect(sessionGate.classifications, [
        AuthSessionClassification.passwordRecovery,
      ]);

      classification.complete();
      await _waitUntil(() => received.length == 2);

      expect(errors, isEmpty);
      expect(received.map((event) => event.type), [
        IdentityAuthEventType.sessionTransition,
        IdentityAuthEventType.passwordRecovery,
      ]);
    },
  );

  test(
    'classification failure becomes a fail-closed event, not a stream error',
    () async {
      sessionGate.classificationError = StateError(
        'secure storage unavailable',
      );
      final repository = SupabaseIdentityRepository(gateway, sessionGate);
      final received = <IdentityAuthEvent>[];
      final errors = <Object>[];
      final subscription = repository.authEvents.listen(
        received.add,
        onError: errors.add,
      );
      addTearDown(subscription.cancel);

      authStates.add(AuthState(AuthChangeEvent.signedIn, _session('new-user')));
      await _waitUntil(() => received.length == 2 || errors.isNotEmpty);

      expect(errors, isEmpty);
      expect(received.map((event) => event.type), [
        IdentityAuthEventType.sessionTransition,
        IdentityAuthEventType.sessionInvalid,
      ]);
      expect(received.last.userId, 'new-user');
    },
  );

  test(
    'signed-out event waits for the durable session gate to clear',
    () async {
      final clearing = Completer<void>();
      sessionGate.clearBarrier = clearing;
      final repository = SupabaseIdentityRepository(gateway, sessionGate);
      final received = <IdentityAuthEvent>[];
      final errors = <Object>[];
      final subscription = repository.authEvents.listen(
        received.add,
        onError: errors.add,
      );
      addTearDown(subscription.cancel);
      addTearDown(() {
        if (!clearing.isCompleted) clearing.complete();
      });

      authStates.add(const AuthState(AuthChangeEvent.signedOut, null));
      await _waitUntil(() => sessionGate.clearCalls == 1);

      expect(errors, isEmpty);
      expect(received.map((event) => event.type), [
        IdentityAuthEventType.sessionTransition,
      ]);

      clearing.complete();
      await _waitUntil(() => received.length == 2);

      expect(received.map((event) => event.type), [
        IdentityAuthEventType.sessionTransition,
        IdentityAuthEventType.signedOut,
      ]);
    },
  );

  test(
    'explicit sign-out does not complete before the durable gate clears',
    () async {
      final clearing = Completer<void>();
      sessionGate.clearBarrier = clearing;
      when(() => auth.signOut()).thenAnswer((_) async {});
      final repository = SupabaseIdentityRepository(gateway, sessionGate);
      var completed = false;
      addTearDown(() {
        if (!clearing.isCompleted) clearing.complete();
      });

      final signingOut = repository.signOut().then((_) => completed = true);
      await _waitUntil(() => sessionGate.clearCalls == 1);

      expect(completed, isFalse);
      verify(() => auth.signOut()).called(1);

      clearing.complete();
      await signingOut;
      expect(completed, isTrue);
    },
  );

  test(
    'discard awaits durable clear and absorbs an early revocation failure',
    () async {
      final clearing = Completer<void>();
      sessionGate.clearBarrier = clearing;
      when(() => auth.signOut()).thenAnswer(
        (_) async => throw AuthRetryableFetchException(message: 'offline'),
      );
      final repository = SupabaseIdentityRepository(gateway, sessionGate);
      var completed = false;
      addTearDown(() {
        if (!clearing.isCompleted) clearing.complete();
      });

      final discarding = repository.discardSession().then(
        (_) => completed = true,
      );
      await _waitUntil(() => sessionGate.clearCalls == 1);

      expect(completed, isFalse);
      clearing.complete();
      await discarding;
      expect(completed, isTrue);
    },
  );

  test(
    'password recovery finishes with a fresh password-authenticated session',
    () async {
      const email = 'recovery-user@example.invalid';
      const password = 'UpdatedPassword!';
      final recoverySession = _session('recovery-user', email: email);
      final passwordSession = _session('recovery-user', email: email);
      when(() => auth.currentUser).thenReturn(recoverySession.user);
      when(
        () => auth.updateUser(UserAttributes(password: password)),
      ).thenAnswer(
        (_) async => UserResponse.fromJson(recoverySession.user.toJson()),
      );
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(
        () => auth.signInWithPassword(email: email, password: password),
      ).thenAnswer(
        (_) async =>
            AuthResponse(session: passwordSession, user: passwordSession.user),
      );
      final repository = SupabaseIdentityRepository(gateway, sessionGate);

      await repository.updatePassword(password);

      verifyInOrder([
        () => auth.updateUser(UserAttributes(password: password)),
        () => auth.signOut(),
        () => auth.signInWithPassword(email: email, password: password),
      ]);
      expect(sessionGate.clearCalls, 1);
      expect(sessionGate.classifications, [
        AuthSessionClassification.authenticated,
      ]);
    },
  );

  test('sign-up reports when email confirmation is required', () async {
    const email = 'new-user@example.invalid';
    const password = 'SecurePassword!';
    final user = _session('new-user', email: email).user;
    when(
      () => auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'campusconnect://auth-callback',
      ),
    ).thenAnswer((_) async => AuthResponse(user: user));
    final repository = SupabaseIdentityRepository(gateway, sessionGate);

    final result = await repository.signUp(
      email: '  NEW-USER@example.invalid ',
      password: password,
    );

    expect(result.confirmationRequired, isTrue);
    expect(sessionGate.classificationCalls, 0);
  });

  test('sign-up classifies an immediately authenticated session', () async {
    const email = 'instant-user@example.invalid';
    const password = 'SecurePassword!';
    final session = _session('instant-user', email: email);
    when(
      () => auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'campusconnect://auth-callback',
      ),
    ).thenAnswer(
      (_) async => AuthResponse(session: session, user: session.user),
    );
    final repository = SupabaseIdentityRepository(gateway, sessionGate);

    final result = await repository.signUp(email: email, password: password);

    expect(result.confirmationRequired, isFalse);
    expect(sessionGate.classifications, [
      AuthSessionClassification.authenticated,
    ]);
  });

  test(
    'retryable refresh failure is propagated without clearing the session',
    () async {
      final expired = _session('offline-user', expired: true);
      when(() => auth.currentSession).thenReturn(expired);
      when(
        () => auth.refreshSession(),
      ).thenThrow(AuthRetryableFetchException(message: 'offline'));
      final repository = SupabaseIdentityRepository(gateway, sessionGate);

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<AuthRetryableFetchException>()),
      );
      expect(sessionGate.classificationCalls, 0);
      verifyNever(() => auth.signOut());
    },
  );

  test('missing session during refresh resolves to signed out', () async {
    final expired = _session('missing-user', expired: true);
    when(() => auth.currentSession).thenReturn(expired);
    when(() => auth.refreshSession()).thenThrow(AuthSessionMissingException());
    final repository = SupabaseIdentityRepository(gateway, sessionGate);

    expect(await repository.restoreSession(), RestoredIdentitySession.none);
  });
}

class _MockBackendGateway extends Mock implements BackendGateway {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _ControllableSessionGate implements AuthSessionGate {
  Completer<void>? classificationBarrier;
  Completer<void>? clearBarrier;
  Object? classificationError;
  int classifyCalls = 0;
  int classificationCalls = 0;
  int clearCalls = 0;
  final List<AuthSessionClassification> classifications = [];

  @override
  Future<AuthSessionClassification> classificationFor(Session session) async {
    classificationCalls += 1;
    return AuthSessionClassification.authenticated;
  }

  @override
  Future<void> classify(
    Session session,
    AuthSessionClassification classification,
  ) async {
    classifyCalls += 1;
    classifications.add(classification);
    final error = classificationError;
    if (error != null) throw error;
    await classificationBarrier?.future;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    await clearBarrier?.future;
  }
}

Session _session(String userId, {bool expired = false, String? email}) {
  final expiresAt =
      DateTime.now()
          .toUtc()
          .add(expired ? const Duration(hours: -1) : const Duration(hours: 1))
          .millisecondsSinceEpoch ~/
      Duration.millisecondsPerSecond;
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': userId,
            'session_id': 'session-$userId',
            'exp': expiresAt,
          }),
        ),
      )
      .replaceAll('=', '');
  return Session(
    accessToken: 'e30.$payload.signature',
    refreshToken: 'refresh-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      email: email,
      createdAt: '2026-01-01T00:00:00.000Z',
    ),
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    if (condition()) return;
  }
  fail('Timed out waiting for an asynchronous condition.');
}
