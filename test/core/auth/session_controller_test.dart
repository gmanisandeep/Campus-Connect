import 'dart:async';
import 'dart:convert';

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
  const studentGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Example Campus',
    role: AppRole.student,
    permissions: {AppPermission.attendanceReadOwn},
  );
  const facultyGrant = AccessGrant(
    membershipId: 'membership',
    institutionId: 'institution',
    institutionName: 'Example Campus',
    role: AppRole.faculty,
    permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
  );
  const multiRoleIdentity = IdentityContext(
    userId: 'user',
    displayName: 'Test User',
    profileCompleted: true,
    memberships: [
      MembershipSummary(
        id: 'membership',
        institutionId: 'institution',
        institutionName: 'Example Campus',
        institutionActive: true,
        status: MembershipStatus.active,
        grants: [studentGrant, facultyGrant],
      ),
    ],
  );

  test(
    'restores multi-role identity and scopes permissions after selection',
    () async {
      final repository = _FakeIdentityRepository(multiRoleIdentity);
      final store = _MemoryKeyValueStore();
      final container = _container(repository, store);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.unknown,
      );
      await _waitForStatus(container, SessionStatus.selectionRequired);

      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('institution', AppRole.faculty);
      final session = container.read(sessionControllerProvider);
      expect(session.status, SessionStatus.authenticated);
      expect(session.activeRole, AppRole.faculty);
      expect(session.can(AppPermission.attendanceRecord), isTrue);
      expect(session.can(AppPermission.attendanceReadOwn), isFalse);
      final storedSelection =
          jsonDecode((await store.readString('identity.active_access'))!)
              as Map<String, dynamic>;
      expect(storedSelection['user_id'], 'user');
    },
  );

  test(
    'valid invitation resolves to onboarding instead of authority',
    () async {
      final repository = _FakeIdentityRepository(
        IdentityContext(
          userId: 'invited-user',
          profileCompleted: false,
          memberships: [
            MembershipSummary(
              id: 'invitation',
              institutionId: 'institution',
              institutionName: 'Example Campus',
              institutionActive: true,
              status: MembershipStatus.invited,
              invitationExpiresAt: DateTime.now().toUtc().add(
                const Duration(days: 1),
              ),
              grants: const [studentGrant],
            ),
          ],
        ),
      );
      final container = _container(repository, _MemoryKeyValueStore());
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitForStatus(container, SessionStatus.onboarding);

      expect(
        container.read(sessionControllerProvider).isAuthenticated,
        isFalse,
      );
    },
  );

  test(
    'an active user can review and accept an additional invitation',
    () async {
      const additionalGrant = AccessGrant(
        membershipId: 'additional-invitation',
        institutionId: 'additional-institution',
        institutionName: 'Second Campus',
        role: AppRole.student,
        permissions: {AppPermission.attendanceReadOwn},
      );
      final identity = IdentityContext(
        userId: 'existing-user',
        displayName: 'Existing User',
        profileCompleted: true,
        memberships: [
          const MembershipSummary(
            id: 'membership',
            institutionId: 'institution',
            institutionName: 'Example Campus',
            institutionActive: true,
            status: MembershipStatus.active,
            grants: [studentGrant],
          ),
          MembershipSummary(
            id: 'additional-invitation',
            institutionId: 'additional-institution',
            institutionName: 'Second Campus',
            institutionActive: true,
            status: MembershipStatus.invited,
            invitationExpiresAt: DateTime.now().toUtc().add(
              const Duration(days: 1),
            ),
            grants: const [additionalGrant],
          ),
        ],
      );
      final repository = _FakeIdentityRepository(identity);
      final container = _container(repository, _MemoryKeyValueStore());
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitForStatus(container, SessionStatus.authenticated);

      container
          .read(sessionControllerProvider.notifier)
          .startInvitationAcceptance();

      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.onboarding,
      );
      expect(
        container.read(sessionControllerProvider).identity,
        same(identity),
      );

      await container
          .read(sessionControllerProvider.notifier)
          .cancelInvitationAcceptance();

      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.authenticated,
      );
    },
  );

  test('suspended membership resolves to a blocked state', () async {
    final repository = _FakeIdentityRepository(
      const IdentityContext(
        userId: 'suspended-user',
        profileCompleted: true,
        memberships: [
          MembershipSummary(
            id: 'suspended-membership',
            institutionId: 'institution',
            institutionName: 'Example Campus',
            institutionActive: true,
            status: MembershipStatus.suspended,
            grants: [studentGrant],
          ),
        ],
      ),
    );
    final container = _container(repository, _MemoryKeyValueStore());
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    container.read(sessionControllerProvider);
    await _waitForStatus(container, SessionStatus.accessBlocked);

    expect(
      container.read(sessionControllerProvider).blockReason,
      AccessBlockReason.suspended,
    );
  });

  test('expired invitation never becomes active access', () async {
    final repository = _FakeIdentityRepository(
      IdentityContext(
        userId: 'expired-user',
        profileCompleted: false,
        memberships: [
          MembershipSummary(
            id: 'expired-invitation',
            institutionId: 'institution',
            institutionName: 'Example Campus',
            institutionActive: true,
            status: MembershipStatus.invited,
            invitationExpiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 1),
            ),
            grants: const [studentGrant],
          ),
        ],
      ),
    );
    final container = _container(repository, _MemoryKeyValueStore());
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    container.read(sessionControllerProvider);
    await _waitForStatus(container, SessionStatus.accessBlocked);

    expect(
      container.read(sessionControllerProvider).blockReason,
      AccessBlockReason.expiredInvitation,
    );
  });

  test(
    'password recovery remains fail-closed across controller recreation',
    () async {
      final repository = _FakeIdentityRepository(multiRoleIdentity);
      final store = _MemoryKeyValueStore();
      final firstContainer = _container(repository, store);
      addTearDown(repository.dispose);

      firstContainer.read(sessionControllerProvider);
      await _waitForStatus(firstContainer, SessionStatus.selectionRequired);
      expect(repository.identityLoadCount, 1);

      repository.emit(
        const IdentityAuthEvent(
          type: IdentityAuthEventType.passwordRecovery,
          userId: 'user',
        ),
      );
      await _waitForStatus(firstContainer, SessionStatus.passwordRecovery);
      repository.restoredSession = RestoredIdentitySession.passwordRecovery;
      firstContainer.dispose();

      final restoredContainer = _container(repository, store);
      addTearDown(restoredContainer.dispose);
      restoredContainer.read(sessionControllerProvider);
      await _waitForStatus(restoredContainer, SessionStatus.passwordRecovery);
      expect(repository.identityLoadCount, 1);

      repository.restoredSession = RestoredIdentitySession.authenticated;
      await restoredContainer
          .read(sessionControllerProvider.notifier)
          .finishPasswordRecovery();
      await _waitForStatus(restoredContainer, SessionStatus.selectionRequired);
      expect(repository.identityLoadCount, 2);
    },
  );

  test(
    'an unclassified session is discarded without loading identity',
    () async {
      final repository = _FakeIdentityRepository(
        multiRoleIdentity,
        restoredSession: RestoredIdentitySession.unclassified,
      );
      final store = _MemoryKeyValueStore();
      final container = _container(repository, store);
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitForStatus(container, SessionStatus.signedOut);

      expect(repository.discardCount, 1);
      expect(repository.identityLoadCount, 0);
    },
  );

  test(
    'in-flight identity resolution cannot overwrite password recovery',
    () async {
      final repository = _FakeIdentityRepository(multiRoleIdentity);
      final container = _container(repository, _MemoryKeyValueStore());
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitForStatus(container, SessionStatus.selectionRequired);

      final applying = container
          .read(sessionControllerProvider.notifier)
          .applyIdentityContext(multiRoleIdentity);
      repository.emit(
        const IdentityAuthEvent(
          type: IdentityAuthEventType.passwordRecovery,
          userId: 'user',
        ),
      );
      await _waitForStatus(container, SessionStatus.passwordRecovery);
      await applying;

      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.passwordRecovery,
      );
    },
  );

  test('saved access from another user is ignored and removed', () async {
    final repository = _FakeIdentityRepository(multiRoleIdentity);
    final store = _MemoryKeyValueStore();
    await store.writeString(
      'identity.active_access',
      jsonEncode({
        'user_id': 'another-user',
        'institution_id': 'institution',
        'role': AppRole.faculty.databaseKey,
      }),
    );
    final container = _container(repository, store);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    container.read(sessionControllerProvider);
    await _waitForStatus(container, SessionStatus.selectionRequired);

    expect(container.read(sessionControllerProvider).activeGrant, isNull);
    expect(await store.readString('identity.active_access'), isNull);
  });

  test(
    'access selection cannot promote a same-user recovery session',
    () async {
      final repository = _FakeIdentityRepository(multiRoleIdentity);
      final container = _container(repository, _MemoryKeyValueStore());
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      container.read(sessionControllerProvider);
      await _waitForStatus(container, SessionStatus.selectionRequired);

      repository.restoredSession = RestoredIdentitySession.passwordRecovery;
      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('institution', AppRole.faculty);
      await _waitForStatus(container, SessionStatus.passwordRecovery);

      expect(
        container.read(sessionControllerProvider).isAuthenticated,
        isFalse,
      );
      expect(container.read(sessionControllerProvider).permissions, isEmpty);
    },
  );
}

ProviderContainer _container(
  IdentityRepository repository,
  KeyValueStore store,
) => ProviderContainer(
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
    keyValueStoreProvider.overrideWithValue(store),
  ],
);

Future<void> _waitForStatus(
  ProviderContainer container,
  SessionStatus expected,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    if (container.read(sessionControllerProvider).status == expected) return;
  }
  fail(
    'Expected $expected, got '
    '${container.read(sessionControllerProvider).status}.',
  );
}

class _FakeIdentityRepository implements IdentityRepository {
  _FakeIdentityRepository(
    this.context, {
    this.restoredSession = RestoredIdentitySession.authenticated,
  });

  final IdentityContext context;
  RestoredIdentitySession restoredSession;
  int identityLoadCount = 0;
  int discardCount = 0;
  final StreamController<IdentityAuthEvent> _events =
      StreamController<IdentityAuthEvent>.broadcast();

  @override
  Stream<IdentityAuthEvent> get authEvents => _events.stream;

  @override
  String? get currentUserId => context.userId;

  void emit(IdentityAuthEvent event) => _events.add(event);

  Future<void> dispose() => _events.close();

  @override
  Future<void> discardSession() async {
    discardCount += 1;
    emit(const IdentityAuthEvent(type: IdentityAuthEventType.signedOut));
  }

  @override
  Future<IdentityContext> acceptMyInvitation({
    required String membershipId,
    required String displayName,
  }) async => context;

  @override
  Future<IdentityContext> completeMyProfile(String displayName) async =>
      context;

  @override
  Future<IdentityContext> loadMyIdentityContext() async {
    identityLoadCount += 1;
    return context;
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<RestoredIdentitySession> restoreSession() async => restoredSession;

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
  Future<void> signOut() async {}

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
