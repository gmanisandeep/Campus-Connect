import 'dart:convert';

import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthSessionClassification { authenticated, passwordRecovery, unclassified }

abstract interface class AuthSessionGate {
  Future<AuthSessionClassification> classificationFor(Session session);

  Future<void> classify(
    Session session,
    AuthSessionClassification classification,
  );

  Future<void> clear();
}

class SecureSupabaseLocalStorage extends LocalStorage
    implements AuthSessionGate {
  SecureSupabaseLocalStorage(this._store, {required String namespace})
    : _sessionKey = 'campus_connect.supabase_session.$namespace',
      _classificationKey =
          'campus_connect.supabase_session_classification.$namespace';

  final SecureStore _store;
  final String _sessionKey;
  final String _classificationKey;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<String?> accessToken() => _enqueue(() => _store.read(_sessionKey));

  @override
  Future<AuthSessionClassification> classificationFor(Session session) =>
      _enqueue(() async {
        final fingerprint = _SessionFingerprint.tryFromSession(session);
        if (fingerprint == null) {
          return AuthSessionClassification.unclassified;
        }
        final stored = await _readClassification();
        if (stored == null || !stored.matches(fingerprint)) {
          return AuthSessionClassification.unclassified;
        }
        return stored.classification;
      });

  @override
  Future<void> classify(
    Session session,
    AuthSessionClassification classification,
  ) {
    if (classification == AuthSessionClassification.unclassified) {
      throw ArgumentError.value(
        classification,
        'classification',
        'Use an explicit authenticated or password-recovery classification.',
      );
    }
    final fingerprint = _SessionFingerprint.tryFromSession(session);
    if (fingerprint == null) {
      throw const FormatException(
        'The current Supabase session has no valid session identifier.',
      );
    }
    return _enqueue(
      () => _writeClassification(
        _StoredSessionClassification(
          fingerprint: fingerprint,
          classification: classification,
        ),
      ),
    );
  }

  @override
  Future<void> clear() => removePersistedSession();

  @override
  Future<bool> hasAccessToken() =>
      _enqueue(() async => (await _store.read(_sessionKey)) != null);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    final session = _tryParseSession(persistSessionString);
    final fingerprint = session == null
        ? null
        : _SessionFingerprint.tryFromSession(session);
    return _enqueue(() async {
      final current = await _readClassification();
      final next = fingerprint != null && current?.matches(fingerprint) == true
          ? current!
          : _StoredSessionClassification(
              fingerprint: fingerprint,
              classification: session == null
                  ? AuthSessionClassification.unclassified
                  : _initialClassification(session),
            );

      // Classify first. If the process stops between these writes, an old
      // session cannot match the new classification and therefore fails closed.
      await _writeClassification(next);
      await _store.write(_sessionKey, persistSessionString);
    });
  }

  @override
  Future<void> removePersistedSession() => _enqueue(() async {
    // Removing trust first makes a partial sign-out fail closed.
    await _store.delete(_classificationKey);
    await _store.delete(_sessionKey);
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Session? _tryParseSession(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      return Session.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  Future<_StoredSessionClassification?> _readClassification() async {
    final encoded = await _store.read(_classificationKey);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return null;
      }
      final classification = AuthSessionClassification.values
          .where((value) => value.name == decoded['classification'])
          .firstOrNull;
      if (classification == null) return null;
      final userId = decoded['user_id'];
      final sessionId = decoded['session_id'];
      final fingerprint =
          userId is String &&
              userId.isNotEmpty &&
              sessionId is String &&
              sessionId.isNotEmpty
          ? _SessionFingerprint(userId: userId, sessionId: sessionId)
          : null;
      return _StoredSessionClassification(
        fingerprint: fingerprint,
        classification: classification,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _writeClassification(
    _StoredSessionClassification classification,
  ) => _store.write(
    _classificationKey,
    jsonEncode({
      'version': 1,
      'user_id': classification.fingerprint?.userId,
      'session_id': classification.fingerprint?.sessionId,
      'classification': classification.classification.name,
    }),
  );

  AuthSessionClassification _initialClassification(Session session) {
    final claims = _SessionFingerprint.tryDecodeClaims(session.accessToken);
    final authenticationMethods = claims?['amr'];
    final methods = authenticationMethods is List
        ? authenticationMethods
              .whereType<Map<String, dynamic>>()
              .map((entry) => entry['method'])
              .whereType<String>()
              .toSet()
        : const <String>{};
    if (methods.contains('password')) {
      return AuthSessionClassification.authenticated;
    }
    // CampusConnect currently supports password sign-in only. A lone OTP
    // session is therefore a password-recovery callback, not a login method.
    if (methods.length == 1 && methods.contains('otp')) {
      return AuthSessionClassification.passwordRecovery;
    }
    return AuthSessionClassification.unclassified;
  }
}

class _StoredSessionClassification {
  const _StoredSessionClassification({
    required this.fingerprint,
    required this.classification,
  });

  final _SessionFingerprint? fingerprint;
  final AuthSessionClassification classification;

  bool matches(_SessionFingerprint other) => fingerprint == other;
}

class _SessionFingerprint {
  const _SessionFingerprint({required this.userId, required this.sessionId});

  final String userId;
  final String sessionId;

  static _SessionFingerprint? tryFromSession(Session session) {
    final claims = tryDecodeClaims(session.accessToken);
    final sessionId = claims?['session_id'];
    if (session.user.id.isEmpty || sessionId is! String || sessionId.isEmpty) {
      return null;
    }
    return _SessionFingerprint(userId: session.user.id, sessionId: sessionId);
  }

  static Map<String, dynamic>? tryDecodeClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _SessionFingerprint &&
      other.userId == userId &&
      other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(userId, sessionId);
}
