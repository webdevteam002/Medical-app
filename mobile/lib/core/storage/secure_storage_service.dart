import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String accessTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveAccessToken(String token) async {
    await write(key: accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await read(key: accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await write(key: refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await read(key: refreshTokenKey);
  }
}
