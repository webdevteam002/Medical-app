import 'secure_storage_service.dart';

class AuthSessionService {
  final SecureStorageService _secureStorageService;

  AuthSessionService({SecureStorageService? secureStorageService})
      : _secureStorageService = secureStorageService ?? SecureStorageService();

  /// Determines whether stored authentication credentials exist.
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorageService.getAccessToken();
      return token != null && token.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Reads stored access token if present.
  Future<String?> getAccessToken() async {
    return await _secureStorageService.getAccessToken();
  }

  /// Clears stored access and refresh tokens while preserving device ID.
  Future<void> clearSession() async {
    try {
      await _secureStorageService.delete(
          key: SecureStorageService.accessTokenKey);
      await _secureStorageService.delete(
          key: SecureStorageService.refreshTokenKey);
    } catch (_) {}
  }

  /// Explicit logout convenience method.
  Future<void> logout() async {
    await clearSession();
  }
}
