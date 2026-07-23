import 'dart:async';
import 'dart:convert';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);

class SessionController extends Notifier<AppSession> {
  static const _selectionKey = 'identity.active_access';

  int _resolutionGeneration = 0;
  bool _passwordRecoveryActive = false;
  Future<void> _selectionOperationTail = Future<void>.value();

  @override
  AppSession build() {
    final config = ref.watch(appConfigProvider);

    if (config.enableDemoSession) return _demoSession();
    if (!config.hasBackendConfiguration) {
      return const AppSession.signedOut();
    }

    final repository = ref.watch(identityRepositoryProvider);
    final authSubscription = repository.authEvents.listen(
      _handleAuthEvent,
      onError: _handleAuthStreamError,
    );
    ref.onDispose(() => unawaited(authSubscription.cancel()));
    unawaited(restore());
    return const AppSession.unknown();
  }

  Future<void> restore() async {
    final generation = ++_resolutionGeneration;
    try {
      final repository = ref.read(identityRepositoryProvider);
      final restoredSession = await repository.restoreSession();
      if (generation != _resolutionGeneration || _passwordRecoveryActive) {
        return;
      }
      switch (restoredSession) {
        case RestoredIdentitySession.none:
          await _clearSelection();
          if (generation != _resolutionGeneration || _passwordRecoveryActive) {
            return;
          }
          state = const AppSession.signedOut();
          return;
        case RestoredIdentitySession.passwordRecovery:
          _passwordRecoveryActive = true;
          state = const AppSession.passwordRecovery();
          return;
        case RestoredIdentitySession.unclassified:
          await repository.discardSession();
          await _clearSelection();
          if (generation == _resolutionGeneration && !_passwordRecoveryActive) {
            state = const AppSession.signedOut();
          }
          return;
        case RestoredIdentitySession.authenticated:
      }
      final identity = await repository.loadMyIdentityContext();
      if (generation != _resolutionGeneration || _passwordRecoveryActive) {
        return;
      }
      final resolved = await _resolve(identity);
      if (!await _canCommitIdentity(identity, generation)) return;
      state = resolved;
    } on Object catch (error, stackTrace) {
      if (generation == _resolutionGeneration && !_passwordRecoveryActive) {
        ref
            .read(appLoggerProvider)
            .error(
              'identity.session_resolution_failed',
              error: error,
              stackTrace: stackTrace,
            );
        state = const AppSession.accessBlocked(
          reason: AccessBlockReason.unavailable,
        );
      }
    }
  }

  Future<void> applyIdentityContext(IdentityContext identity) async {
    if (_passwordRecoveryActive) return;
    final generation = ++_resolutionGeneration;
    state = const AppSession.unknown();
    try {
      final resolved = await _resolve(identity);
      if (!await _canCommitIdentity(identity, generation)) return;
      state = resolved;
    } on Object catch (error, stackTrace) {
      if (generation == _resolutionGeneration && !_passwordRecoveryActive) {
        _logResolutionFailure(error, stackTrace);
        state = const AppSession.accessBlocked(
          reason: AccessBlockReason.unavailable,
        );
      }
      rethrow;
    }
  }

  Future<void> selectAccess(String institutionId, AppRole role) async {
    final identity = state.identity;
    final config = ref.read(appConfigProvider);
    if (identity == null || !identity.profileCompleted) {
      ++_resolutionGeneration;
      state = const AppSession.unknown();
      unawaited(restore());
      return;
    }
    if (config.hasBackendConfiguration) {
      final generation = _resolutionGeneration;
      final repository = ref.read(identityRepositoryProvider);
      try {
        final restoredSession = await repository.restoreSession();
        if (generation != _resolutionGeneration ||
            state.identity?.userId != identity.userId) {
          return;
        }
        if (restoredSession != RestoredIdentitySession.authenticated ||
            repository.currentUserId != identity.userId) {
          ++_resolutionGeneration;
          state = const AppSession.unknown();
          unawaited(restore());
          return;
        }
      } on Object catch (error, stackTrace) {
        if (generation == _resolutionGeneration) {
          ++_resolutionGeneration;
          _logResolutionFailure(error, stackTrace);
          state = const AppSession.accessBlocked(
            reason: AccessBlockReason.unavailable,
          );
        }
        return;
      }
    }
    final selected = state.selectAccess(institutionId, role);
    if (identical(selected, state)) return;
    state = selected;
    final payload = jsonEncode({
      'user_id': identity.userId,
      'institution_id': institutionId,
      'role': role.databaseKey,
    });
    try {
      await _runSelectionOperation(
        () =>
            ref.read(keyValueStoreProvider).writeString(_selectionKey, payload),
      );
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            'identity.selection_not_persisted',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  void startAccessSelection() {
    final identity = state.identity;
    if (state.status == SessionStatus.authenticated &&
        identity != null &&
        identity.profileCompleted &&
        identity.activeGrants.length > 1) {
      state = AppSession.selectionRequired(identity);
    }
  }

  void startInvitationAcceptance() {
    final identity = state.identity;
    if (state.status == SessionStatus.authenticated &&
        identity != null &&
        identity.acceptableInvitations.isNotEmpty) {
      state = AppSession.onboarding(identity);
    }
  }

  Future<void> cancelInvitationAcceptance() async {
    final identity = state.identity;
    if (state.status != SessionStatus.onboarding ||
        identity == null ||
        identity.activeGrants.isEmpty ||
        !identity.profileCompleted) {
      return;
    }
    final generation = ++_resolutionGeneration;
    state = const AppSession.unknown();
    try {
      final resolved = await _resolve(identity);
      if (!await _canCommitIdentity(identity, generation)) return;
      state = resolved;
    } on Object catch (error, stackTrace) {
      if (generation == _resolutionGeneration && !_passwordRecoveryActive) {
        _logResolutionFailure(error, stackTrace);
        state = const AppSession.accessBlocked(
          reason: AccessBlockReason.unavailable,
        );
      }
      rethrow;
    }
  }

  Future<void> finishPasswordRecovery() async {
    _passwordRecoveryActive = false;
    await restore();
  }

  Future<void> signOut() async {
    final generation = ++_resolutionGeneration;
    _passwordRecoveryActive = false;
    state = const AppSession.unknown();
    try {
      if (ref.read(appConfigProvider).hasBackendConfiguration) {
        await ref.read(identityRepositoryProvider).signOut();
      }
      await _clearSelection();
      if (generation == _resolutionGeneration) {
        state = const AppSession.signedOut();
      }
    } on Object catch (error, stackTrace) {
      if (generation == _resolutionGeneration) {
        _logResolutionFailure(error, stackTrace);
        state = const AppSession.accessBlocked(
          reason: AccessBlockReason.unavailable,
        );
      }
      rethrow;
    }
  }

  void enterGalleryDemo() {
    final config = ref.read(appConfigProvider);
    if (!config.enableDesignSystemGallery || config.isProduction) return;
    state = _demoSession(userId: 'gallery-user');
  }

  void _handleAuthEvent(IdentityAuthEvent event) {
    switch (event.type) {
      case IdentityAuthEventType.sessionTransition:
        ++_resolutionGeneration;
        _passwordRecoveryActive = false;
        state = const AppSession.unknown();
      case IdentityAuthEventType.sessionInvalid:
        ++_resolutionGeneration;
        _passwordRecoveryActive = false;
        state = const AppSession.accessBlocked(
          reason: AccessBlockReason.unavailable,
        );
        final currentUserId = ref
            .read(identityRepositoryProvider)
            .currentUserId;
        if (event.userId != null && currentUserId == event.userId) {
          unawaited(_discardInvalidSession());
        }
      case IdentityAuthEventType.passwordRecovery:
        ++_resolutionGeneration;
        _passwordRecoveryActive = true;
        state = const AppSession.passwordRecovery();
      case IdentityAuthEventType.signedOut:
        ++_resolutionGeneration;
        _passwordRecoveryActive = false;
        unawaited(_clearSelection());
        state = const AppSession.signedOut();
      case IdentityAuthEventType.sessionChanged:
        if (!_passwordRecoveryActive) unawaited(restore());
    }
  }

  void _handleAuthStreamError(Object error, StackTrace stackTrace) {
    ++_resolutionGeneration;
    _passwordRecoveryActive = false;
    _logResolutionFailure(error, stackTrace);
    // GoTrue retains its current session for retryable refresh failures. Keep
    // it durable but remove local authority until a later event can revalidate.
    state = const AppSession.accessBlocked(
      reason: AccessBlockReason.unavailable,
    );
  }

  Future<void> _discardInvalidSession() async {
    try {
      await ref.read(identityRepositoryProvider).discardSession();
    } on Object catch (error, stackTrace) {
      _logResolutionFailure(error, stackTrace);
    }
  }

  Future<bool> _canCommitIdentity(
    IdentityContext identity,
    int generation,
  ) async {
    if (generation != _resolutionGeneration || _passwordRecoveryActive) {
      return false;
    }
    final repository = ref.read(identityRepositoryProvider);
    final restoredSession = await repository.restoreSession();
    if (generation != _resolutionGeneration || _passwordRecoveryActive) {
      return false;
    }
    if (restoredSession == RestoredIdentitySession.authenticated &&
        repository.currentUserId == identity.userId) {
      return true;
    }
    state = const AppSession.unknown();
    unawaited(restore());
    return false;
  }

  Future<AppSession> _resolve(IdentityContext identity) async {
    final grants = identity.activeGrants;
    if (grants.isEmpty) {
      if (identity.acceptableInvitations.isNotEmpty) {
        return AppSession.onboarding(identity);
      }
      return AppSession.accessBlocked(
        reason: _blockedReason(identity),
        identity: identity,
      );
    }
    if (!identity.profileCompleted) return AppSession.onboarding(identity);

    final storedSelection = await _readSelection(identity.userId);
    if (storedSelection != null) {
      final grant = identity.findGrant(
        storedSelection.institutionId,
        storedSelection.role,
      );
      if (grant != null) {
        return AppSession.authenticated(identity: identity, activeGrant: grant);
      }
      await _clearSelection();
    }
    if (grants.length == 1) {
      return AppSession.authenticated(
        identity: identity,
        activeGrant: grants.single,
      );
    }
    return AppSession.selectionRequired(identity);
  }

  AccessBlockReason _blockedReason(IdentityContext identity) {
    final memberships = identity.memberships;
    if (memberships.any(
      (membership) => membership.status == MembershipStatus.suspended,
    )) {
      return AccessBlockReason.suspended;
    }
    if (memberships.any(
      (membership) =>
          membership.status == MembershipStatus.active &&
          !membership.institutionActive,
    )) {
      return AccessBlockReason.inactiveInstitution;
    }
    if (memberships.any(
      (membership) =>
          membership.status == MembershipStatus.invited &&
          membership.invitationExpired,
    )) {
      return AccessBlockReason.expiredInvitation;
    }
    if (memberships.any(
      (membership) => membership.status == MembershipStatus.active,
    )) {
      return AccessBlockReason.missingRole;
    }
    return AccessBlockReason.noMembership;
  }

  Future<_StoredSelection?> _readSelection(String userId) async {
    try {
      final encoded = await _runSelectionOperation(
        () => ref.read(keyValueStoreProvider).readString(_selectionKey),
      );
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?>) {
        await _clearSelection();
        return null;
      }
      final storedUserId = decoded['user_id'];
      final institutionId = decoded['institution_id'];
      final roleKey = decoded['role'];
      if (storedUserId != userId ||
          institutionId is! String ||
          roleKey is! String) {
        await _clearSelection();
        return null;
      }
      final role = AppRole.fromDatabaseKey(roleKey);
      if (role == null) {
        await _clearSelection();
        return null;
      }
      return _StoredSelection(institutionId, role);
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            'identity.saved_selection_invalid',
            error: error,
            stackTrace: stackTrace,
          );
      return null;
    }
  }

  Future<void> _clearSelection() => _runSelectionOperation(
    () => ref.read(keyValueStoreProvider).delete(_selectionKey),
  );

  Future<T> _runSelectionOperation<T>(Future<T> Function() operation) {
    final result = _selectionOperationTail.then((_) => operation());
    _selectionOperationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  void _logResolutionFailure(Object error, StackTrace stackTrace) {
    ref
        .read(appLoggerProvider)
        .error(
          'identity.session_resolution_failed',
          error: error,
          stackTrace: stackTrace,
        );
  }

  AppSession _demoSession({String userId = 'development-user'}) {
    const studentGrant = AccessGrant(
      membershipId: 'development-membership',
      institutionId: 'development-institution',
      institutionName: 'Development institution',
      role: AppRole.student,
      permissions: {AppPermission.attendanceReadOwn},
    );
    const facultyGrant = AccessGrant(
      membershipId: 'development-membership',
      institutionId: 'development-institution',
      institutionName: 'Development institution',
      role: AppRole.faculty,
      permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
    );
    final identity = IdentityContext(
      userId: userId,
      displayName: 'Development preview',
      profileCompleted: true,
      memberships: const [
        MembershipSummary(
          id: 'development-membership',
          institutionId: 'development-institution',
          institutionName: 'Development institution',
          institutionActive: true,
          status: MembershipStatus.active,
          grants: [studentGrant, facultyGrant],
        ),
      ],
    );
    return AppSession.authenticated(
      identity: identity,
      activeGrant: studentGrant,
    );
  }
}

class _StoredSelection {
  const _StoredSelection(this.institutionId, this.role);

  final String institutionId;
  final AppRole role;
}
