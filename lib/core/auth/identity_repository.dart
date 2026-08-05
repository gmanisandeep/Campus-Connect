import 'package:campus_connect/core/auth/access_grant.dart';

enum IdentityAuthEventType {
  sessionTransition,
  sessionChanged,
  passwordRecovery,
  sessionInvalid,
  signedOut,
}

enum RestoredIdentitySession {
  none,
  authenticated,
  passwordRecovery,
  unclassified,
}

class AccountCreationResult {
  const AccountCreationResult({required this.confirmationRequired});

  final bool confirmationRequired;
}

class IdentityAuthEvent {
  const IdentityAuthEvent({required this.type, this.userId});

  final IdentityAuthEventType type;
  final String? userId;
}

abstract interface class IdentityRepository {
  Stream<IdentityAuthEvent> get authEvents;
  String? get currentUserId;

  Future<RestoredIdentitySession> restoreSession();
  Future<AccountCreationResult> signUp({
    required String email,
    required String password,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> requestPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<IdentityContext> loadMyIdentityContext();
  Future<IdentityContext> acceptMyInvitation({
    required String membershipId,
    required String displayName,
  });
  Future<IdentityContext> completeMyProfile(String displayName);
  Future<void> signOut();
  Future<void> discardSession();
}
