import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/storage/auth_session_service.dart';
import 'package:medstudy/core/storage/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    storage.remove(key);
  }
}

void main() {
  group('AuthSessionService Tests', () {
    late FakeSecureStorageService fakeStorage;
    late AuthSessionService authSessionService;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      authSessionService =
          AuthSessionService(secureStorageService: fakeStorage);
    });

    test('1. Returns false when no credentials exist', () async {
      final isAuth = await authSessionService.isAuthenticated();
      expect(isAuth, isFalse);
    });

    test('2. Returns true when valid stored access token exists', () async {
      fakeStorage.storage[SecureStorageService.accessTokenKey] =
          'valid_token_123';
      final isAuth = await authSessionService.isAuthenticated();
      expect(isAuth, isTrue);
    });

    test('3. clearSession removes stored access and refresh tokens', () async {
      fakeStorage.storage[SecureStorageService.accessTokenKey] =
          'valid_token_123';
      fakeStorage.storage[SecureStorageService.refreshTokenKey] =
          'valid_refresh_123';

      await authSessionService.clearSession();

      expect(fakeStorage.storage[SecureStorageService.accessTokenKey], isNull);
      expect(fakeStorage.storage[SecureStorageService.refreshTokenKey], isNull);
      expect(await authSessionService.isAuthenticated(), isFalse);
    });
  });
}
