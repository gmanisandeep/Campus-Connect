import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  const PlatformSecureStore.sensitiveDataKeys()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          keyCipherAlgorithm:
              KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          sharedPreferencesName: 'campus_connect_sensitive_keys',
          preferencesKeyPrefix: 'campus_connect_sensitive_',
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
          synchronizable: false,
        ),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
