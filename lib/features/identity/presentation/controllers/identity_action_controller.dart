import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final identityActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<IdentityActionController, void>(
      IdentityActionController.new,
    );

class IdentityActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) =>
      _run(() async {
        await ref
            .read(identityRepositoryProvider)
            .signIn(email: email, password: password);
        await ref.read(sessionControllerProvider.notifier).restore();
      });

  Future<void> requestPasswordReset(String email) => _run(
    () => ref.read(identityRepositoryProvider).requestPasswordReset(email),
  );

  Future<void> updatePassword(String password) => _run(() async {
    await ref.read(identityRepositoryProvider).updatePassword(password);
    await ref.read(sessionControllerProvider.notifier).finishPasswordRecovery();
  });

  Future<void> acceptInvitation({
    required String membershipId,
    required String displayName,
    String? password,
  }) => _run(() async {
    if (password != null) {
      await ref.read(identityRepositoryProvider).updatePassword(password);
    }
    final identity = await ref
        .read(identityRepositoryProvider)
        .acceptMyInvitation(
          membershipId: membershipId,
          displayName: displayName,
        );
    await ref
        .read(sessionControllerProvider.notifier)
        .applyIdentityContext(identity);
  });

  Future<void> completeProfile(String displayName) => _run(() async {
    final identity = await ref
        .read(identityRepositoryProvider)
        .completeMyProfile(displayName);
    await ref
        .read(sessionControllerProvider.notifier)
        .applyIdentityContext(identity);
  });

  Future<void> signOut() =>
      _run(() => ref.read(sessionControllerProvider.notifier).signOut());

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}
