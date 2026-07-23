import 'dart:math';

import 'package:campus_connect/core/storage/secure_store.dart';

class LocalDatabaseKeyStore {
  LocalDatabaseKeyStore(
    this._store, {
    required String namespace,
    Random? random,
  }) : _keyName = 'campus_connect.local_database_key.v1.$namespace',
       _random = random ?? Random.secure();

  final SecureStore _store;
  final String _keyName;
  final Random _random;
  Future<void> _operationTail = Future<void>.value();

  Future<String?> readKey() => _enqueue(() => _store.read(_keyName));

  Future<String> createKey() => _enqueue(() async {
    final existing = await _store.read(_keyName);
    if (existing != null && _isValidKey(existing)) return existing;
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final key = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await _store.write(_keyName, key);
    return key;
  });

  Future<void> deleteKey() => _enqueue(() => _store.delete(_keyName));

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}

bool _isValidKey(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
