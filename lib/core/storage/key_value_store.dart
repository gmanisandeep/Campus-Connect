import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStore {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> delete(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  @override
  Future<String?> readString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }
}
