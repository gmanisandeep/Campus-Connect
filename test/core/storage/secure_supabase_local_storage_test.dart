import 'dart:convert';

import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:campus_connect/core/storage/secure_supabase_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('password sessions are durably classified as authenticated', () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabaseLocalStorage(store, namespace: 'test');
    final session = _session(
      userId: 'user-1',
      sessionId: 'session-1',
      methods: const ['password'],
    );

    await storage.persistSession(jsonEncode(session.toJson()));

    expect(
      await storage.classificationFor(session),
      AuthSessionClassification.authenticated,
    );
    expect(await storage.hasAccessToken(), isTrue);
  });

  test('OTP recovery remains recovery until explicitly promoted', () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabaseLocalStorage(store, namespace: 'test');
    final recovery = _session(
      userId: 'user-1',
      sessionId: 'session-1',
      methods: const ['otp'],
    );
    await storage.persistSession(jsonEncode(recovery.toJson()));
    expect(
      await storage.classificationFor(recovery),
      AuthSessionClassification.passwordRecovery,
    );

    await storage.classify(recovery, AuthSessionClassification.authenticated);
    final refreshed = _session(
      userId: 'user-1',
      sessionId: 'session-1',
      methods: const ['otp'],
      expiresAt: 4102448400,
    );
    await storage.persistSession(jsonEncode(refreshed.toJson()));

    expect(
      await storage.classificationFor(refreshed),
      AuthSessionClassification.authenticated,
    );
  });

  test('a new session cannot inherit another session classification', () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabaseLocalStorage(store, namespace: 'test');
    final first = _session(
      userId: 'user-1',
      sessionId: 'session-1',
      methods: const ['password'],
    );
    final second = _session(
      userId: 'user-1',
      sessionId: 'session-2',
      methods: const ['otp'],
    );
    await storage.persistSession(jsonEncode(first.toJson()));
    await storage.persistSession(jsonEncode(second.toJson()));

    expect(
      await storage.classificationFor(first),
      AuthSessionClassification.unclassified,
    );
    expect(
      await storage.classificationFor(second),
      AuthSessionClassification.passwordRecovery,
    );
  });

  test(
    'a partial session write invalidates trust before retaining old data',
    () async {
      final store = _MemorySecureStore();
      final storage = SecureSupabaseLocalStorage(store, namespace: 'test');
      final first = _session(
        userId: 'user-1',
        sessionId: 'session-1',
        methods: const ['password'],
      );
      final second = _session(
        userId: 'user-1',
        sessionId: 'session-2',
        methods: const ['otp'],
      );
      final firstEncoded = jsonEncode(first.toJson());
      await storage.persistSession(firstEncoded);

      store.failNextWriteFor = 'campus_connect.supabase_session.test';
      await expectLater(
        storage.persistSession(jsonEncode(second.toJson())),
        throwsStateError,
      );

      expect(await storage.accessToken(), firstEncoded);
      expect(
        await storage.classificationFor(first),
        AuthSessionClassification.unclassified,
      );
    },
  );

  test('malformed classification and sign-out both fail closed', () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabaseLocalStorage(store, namespace: 'test');
    final session = _session(
      userId: 'user-1',
      sessionId: 'session-1',
      methods: const ['password'],
    );
    await storage.persistSession(jsonEncode(session.toJson()));
    store.values['campus_connect.supabase_session_classification.test'] =
        'not-json';
    expect(
      await storage.classificationFor(session),
      AuthSessionClassification.unclassified,
    );

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(
      store.values.containsKey(
        'campus_connect.supabase_session_classification.test',
      ),
      isFalse,
    );
  });
}

Session _session({
  required String userId,
  required String sessionId,
  required List<String> methods,
  int expiresAt = 4102444800,
}) {
  final accessToken = [
    _base64UrlJson({'alg': 'none', 'typ': 'JWT'}),
    _base64UrlJson({
      'sub': userId,
      'session_id': sessionId,
      'exp': expiresAt,
      'amr': methods.map((method) => {'method': method}).toList(),
    }),
    'signature',
  ].join('.');
  return Session(
    accessToken: accessToken,
    refreshToken: 'refresh-$sessionId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-07-18T00:00:00Z',
    ),
  );
}

String _base64UrlJson(Map<String, Object?> value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};
  String? failNextWriteFor;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failNextWriteFor == key) {
      failNextWriteFor = null;
      throw StateError('simulated secure-storage write failure');
    }
    values[key] = value;
  }
}
