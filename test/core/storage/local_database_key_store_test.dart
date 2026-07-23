import 'dart:math';

import 'package:campus_connect/core/storage/local_database_key_store.dart';
import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDatabaseKeyStore', () {
    test('creates one 256-bit lowercase hex key and retains it', () async {
      final secureStore = _MemorySecureStore();
      final keyStore = LocalDatabaseKeyStore(
        secureStore,
        namespace: 'test-environment',
        random: Random(9173),
      );

      final first = await keyStore.createKey();
      final second = await keyStore.createKey();

      expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(second, first);
      expect(await keyStore.readKey(), first);
      expect(secureStore.writeCount, 1);
      expect(secureStore.values, hasLength(1));
      expect(
        secureStore.values.keys.single,
        'campus_connect.local_database_key.v1.test-environment',
      );
    });

    test(
      'serializes concurrent creation so callers receive the same key',
      () async {
        final secureStore = _MemorySecureStore(writeDelay: Duration.zero);
        final keyStore = LocalDatabaseKeyStore(
          secureStore,
          namespace: 'concurrent',
          random: Random(42),
        );

        final keys = await Future.wait(
          List.generate(32, (_) => keyStore.createKey()),
        );

        expect(keys.toSet(), hasLength(1));
        expect(secureStore.writeCount, 1);
      },
    );

    test('replaces a malformed persisted key instead of trusting it', () async {
      final secureStore = _MemorySecureStore();
      const keyName = 'campus_connect.local_database_key.v1.corrupt';
      secureStore.values[keyName] = 'not-a-valid-database-key';
      final keyStore = LocalDatabaseKeyStore(
        secureStore,
        namespace: 'corrupt',
        random: Random(101),
      );

      final replacement = await keyStore.createKey();

      expect(replacement, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(replacement, isNot('not-a-valid-database-key'));
      expect(secureStore.values[keyName], replacement);
      expect(secureStore.writeCount, 1);
    });

    test('namespaces keys and deletes only the requested namespace', () async {
      final secureStore = _MemorySecureStore();
      final first = LocalDatabaseKeyStore(
        secureStore,
        namespace: 'first',
        random: Random(1),
      );
      final second = LocalDatabaseKeyStore(
        secureStore,
        namespace: 'second',
        random: Random(2),
      );
      final secondKey = await second.createKey();
      await first.createKey();

      await first.deleteKey();

      expect(await first.readKey(), isNull);
      expect(await second.readKey(), secondKey);
      expect(secureStore.values, hasLength(1));
    });

    test(
      'a failed operation does not poison later serialized operations',
      () async {
        final secureStore = _MemorySecureStore();
        final keyStore = LocalDatabaseKeyStore(
          secureStore,
          namespace: 'recovery',
          random: Random(3),
        );
        secureStore.failNextWrite = true;

        await expectLater(keyStore.createKey(), throwsStateError);
        final key = await keyStore.createKey();

        expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(await keyStore.readKey(), key);
      },
    );

    test(
      'a failed deletion is reported and a later deletion can recover',
      () async {
        final secureStore = _MemorySecureStore();
        final keyStore = LocalDatabaseKeyStore(
          secureStore,
          namespace: 'delete-recovery',
          random: Random(4),
        );
        final key = await keyStore.createKey();
        secureStore.failNextDelete = true;

        await expectLater(keyStore.deleteKey(), throwsStateError);

        expect(await keyStore.readKey(), key);
        await keyStore.deleteKey();
        expect(await keyStore.readKey(), isNull);
      },
    );
  });
}

class _MemorySecureStore implements SecureStore {
  _MemorySecureStore({this.writeDelay});

  final Duration? writeDelay;
  final Map<String, String> values = {};
  int writeCount = 0;
  bool failNextWrite = false;
  bool failNextDelete = false;

  @override
  Future<void> delete(String key) async {
    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('simulated secure-store deletion failure');
    }
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (writeDelay case final delay?) await Future<void>.delayed(delay);
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated secure-store failure');
    }
    writeCount += 1;
    values[key] = value;
  }
}
