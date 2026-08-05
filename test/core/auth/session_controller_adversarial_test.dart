import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/storage/key_value_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'session transition immediately removes previously resolved authority',
    () async {
      final repository = _AdversarialIdentityRepository(_identity('user-a'));
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(
        () => container.read(sessionControllerProvider).isAuthenticated,
      );

      repository.emit(
        const IdentityAuthEvent(
          type: IdentityAuthEventType.sessionTransition,
          userId: 'user-b',
        ),
      );
      await _waitUntil(
        () =>
            container.read(sessionControllerProvider).status ==
            SessionStatus.unknown,
      );

      final session = container.read(sessionControllerProvider);
      expect(session.identity, isNull);
      expect(session.permissions, isEmpty);
    },
  );

  test(
    'invalid session event fails closed and discards persisted session',
    () async {
      final repository = _AdversarialIdentityRepository(_identity('user-a'));
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(
        () => container.read(sessionControllerProvider).isAuthenticated,
      );

      repository.emit(
        const IdentityAuthEvent(
          type: IdentityAuthEventType.sessionInvalid,
          userId: 'user-a',
        ),
      );
      await _waitUntil(
        () =>
            container.read(sessionControllerProvider).status ==
            SessionStatus.accessBlocked,
      );

      final session = container.read(sessionControllerProvider);
      expect(session.blockReason, AccessBlockReason.unavailable);
      expect(session.identity, isNull);
      await _waitUntil(() => repository.discardCount == 1);
    },
  );

  test(
    'auth event stream errors remove previously resolved authority',
    () async {
      final repository = _AdversarialIdentityRepository(_identity('user-a'));
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(
        () => container.read(sessionControllerProvider).isAuthenticated,
      );

      repository.emitError(StateError('classification failed'));
      await _waitUntil(
        () =>
            container.read(sessionControllerProvider).status ==
            SessionStatus.accessBlocked,
      );

      final session = container.read(sessionControllerProvider);
      expect(session.blockReason, AccessBlockReason.unavailable);
      expect(session.identity, isNull);
      expect(session.permissions, isEmpty);
    },
  );

  test(
    'account swap during identity RPC cannot commit the old identity',
    () async {
      final staleLoad = Completer<IdentityContext>();
      final repository = _AdversarialIdentityRepository(
        _identity('user-a'),
        firstIdentityLoad: staleLoad.future,
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(() => repository.identityLoadCount == 1);

      repository
        ..currentUserId = 'user-b'
        ..context = _identity('user-b');
      staleLoad.complete(_identity('user-a'));

      await _waitUntil(
        () => container.read(sessionControllerProvider).userId == 'user-b',
      );
      expect(container.read(sessionControllerProvider).isAuthenticated, isTrue);
      expect(repository.identityLoadCount, greaterThanOrEqualTo(2));
    },
  );

  test(
    'stale action result cannot restore authority for the previous account',
    () async {
      final oldIdentity = _identity('user-a');
      final repository = _AdversarialIdentityRepository(oldIdentity);
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(
        () => container.read(sessionControllerProvider).userId == 'user-a',
      );

      repository
        ..currentUserId = 'user-b'
        ..context = _identity('user-b')
        ..emit(
          const IdentityAuthEvent(
            type: IdentityAuthEventType.sessionTransition,
            userId: 'user-b',
          ),
        );
      await _waitUntil(
        () =>
            container.read(sessionControllerProvider).status ==
            SessionStatus.unknown,
      );

      await container
          .read(sessionControllerProvider.notifier)
          .applyIdentityContext(oldIdentity);

      await _waitUntil(
        () => container.read(sessionControllerProvider).userId == 'user-b',
      );
      expect(container.read(sessionControllerProvider).isAuthenticated, isTrue);
    },
  );

  test(
    'sign out quiesces local authority before remote sign out completes',
    () async {
      final signOutBarrier = Completer<void>();
      final repository = _AdversarialIdentityRepository(
        _identity('user-a'),
        signOutBarrier: signOutBarrier.future,
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitUntil(
        () => container.read(sessionControllerProvider).isAuthenticated,
      );

      final signingOut = container
          .read(sessionControllerProvider.notifier)
          .signOut();

      final quiesced = container.read(sessionControllerProvider);
      expect(quiesced.isAuthenticated, isFalse);
      expect(quiesced.identity, isNull);
      expect(quiesced.permissions, isEmpty);

      signOutBarrier.complete();
      await signingOut;
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.signedOut,
      );
    },
  );
}

const _grant = AccessGrant(
  membershipId: 'membership',
  institutionId: 'institution',
  institutionName: 'Example Campus',
  role: AppRole.student,
  permissions: {AppPermission.attendanceReadOwn},
);

IdentityContext _identity(String userId) => IdentityContext(
  userId: userId,
  displayName: userId,
  profileCompleted: true,
  memberships: const [
    MembershipSummary(
      id: 'membership',
      institutionId: 'institution',
      institutionName: 'Example Campus',
      institutionActive: true,
      status: MembershipStatus.active,
      grants: [_grant],
    ),
  ],
);

ProviderContainer _container(IdentityRepository repository) =>
    ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: AppEnvironment.test,
            supabaseUrl: 'http://127.0.0.1:54321',
            supabaseAnonKey: 'sb_publishable_test',
            enableDesignSystemGallery: false,
            enableDemoSession: false,
          ),
        ),
        identityRepositoryProvider.overrideWithValue(repository),
        keyValueStoreProvider.overrideWithValue(_MemoryKeyValueStore()),
      ],
    );

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    if (condition()) return;
  }
  fail('Condition did not become true.');
}

class _AdversarialIdentityRepository implements IdentityRepository {
  _AdversarialIdentityRepository(
    this.context, {
    Future<IdentityContext>? firstIdentityLoad,
    Future<void>? signOutBarrier,
  }) : currentUserId = context.userId,
       _firstIdentityLoad = firstIdentityLoad,
       _signOutBarrier = signOutBarrier;

  IdentityContext context;
  @override
  String? currentUserId;
  RestoredIdentitySession restoredSession =
      RestoredIdentitySession.authenticated;
  int identityLoadCount = 0;
  int discardCount = 0;
  final Future<IdentityContext>? _firstIdentityLoad;
  final Future<void>? _signOutBarrier;
  final StreamController<IdentityAuthEvent> _events =
      StreamController<IdentityAuthEvent>.broadcast();

  @override
  Stream<IdentityAuthEvent> get authEvents => _events.stream;

  void emit(IdentityAuthEvent event) => _events.add(event);

  void emitError(Object error) => _events.addError(error);

  Future<void> dispose() => _events.close();

  @override
  Future<void> discardSession() async {
    discardCount += 1;
    currentUserId = null;
    restoredSession = RestoredIdentitySession.none;
  }

  @override
  Future<IdentityContext> loadMyIdentityContext() async {
    identityLoadCount += 1;
    if (identityLoadCount == 1 && _firstIdentityLoad != null) {
      return _firstIdentityLoad;
    }
    return context;
  }

  @override
  Future<RestoredIdentitySession> restoreSession() async => restoredSession;

  @override
  Future<IdentityContext> acceptMyInvitation({
    required String membershipId,
    required String displayName,
  }) async => context;

  @override
  Future<IdentityContext> completeMyProfile(String displayName) async =>
      context;

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<AccountCreationResult> signUp({
    required String email,
    required String password,
  }) async => const AccountCreationResult(confirmationRequired: true);

  @override
  Future<void> signOut() async {
    await _signOutBarrier;
  }

  @override
  Future<void> updatePassword(String password) async {}
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
