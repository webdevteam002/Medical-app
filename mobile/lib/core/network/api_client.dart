import 'dart:async';
import 'package:dio/dio.dart';
import '../../features/auth/data/models/auth_tokens.dart';
import '../config/app_config.dart';
import '../device/device_id_service.dart';
import '../storage/auth_session_service.dart';
import '../storage/secure_storage_service.dart';

/// Shared HTTP client with a single app-wide token refresh lock.
///
/// Multiple datasources used to create separate [ApiClient] instances; when the
/// access JWT expired, Study + Exams refreshed in parallel, the backend rotated
/// the refresh token once, and the losing call cleared the winning tokens.
class ApiClient {
  static ApiClient? _sharedInstance;

  /// Process-wide refresh lock (shared across all instances / datasources).
  static Completer<AuthTokens?>? _sharedRefreshCompleter;

  final Dio _dio;
  final SecureStorageService _secureStorageService;
  final DeviceIdService _deviceIdService;
  final AuthSessionService _authSessionService;

  factory ApiClient({
    Dio? dio,
    SecureStorageService? secureStorageService,
    DeviceIdService? deviceIdService,
    AuthSessionService? authSessionService,
  }) {
    final hasOverrides = dio != null ||
        secureStorageService != null ||
        deviceIdService != null ||
        authSessionService != null;

    if (!hasOverrides) {
      return _sharedInstance ??= ApiClient._();
    }

    return ApiClient._(
      dio: dio,
      secureStorageService: secureStorageService,
      deviceIdService: deviceIdService,
      authSessionService: authSessionService,
    );
  }

  ApiClient._({
    Dio? dio,
    SecureStorageService? secureStorageService,
    DeviceIdService? deviceIdService,
    AuthSessionService? authSessionService,
  })  : _secureStorageService = secureStorageService ?? SecureStorageService(),
        _deviceIdService = deviceIdService ??
            DeviceIdService(secureStorageService: secureStorageService),
        _authSessionService = authSessionService ??
            AuthSessionService(secureStorageService: secureStorageService),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout:
                    const Duration(milliseconds: AppConfig.connectTimeoutMs),
                receiveTimeout:
                    const Duration(milliseconds: AppConfig.receiveTimeoutMs),
                sendTimeout:
                    const Duration(milliseconds: AppConfig.sendTimeoutMs),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceId = await _deviceIdService.getOrCreateDeviceId();
          options.headers['X-Device-Id'] = deviceId;

          final isRefresh = options.path.contains('/auth/refresh');
          if (!isRefresh && !options.headers.containsKey('Authorization')) {
            final token = await _secureStorageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          if (isRefresh) {
            options.headers.remove('Authorization');
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final is401 = error.response?.statusCode == 401;
          final requestPath = error.requestOptions.path;
          final isAuthEndpoint = requestPath.contains('/auth/login') ||
              requestPath.contains('/auth/register') ||
              requestPath.contains('/auth/refresh');
          final isRetry = error.requestOptions.extra['isRetry'] == true;

          if (!is401 || isAuthEndpoint || isRetry) {
            return handler.next(error);
          }

          // True revoke / another device — do not attempt refresh.
          if (_isSessionRevoked(error) || _isDeviceMismatch(error)) {
            await _authSessionService.clearSession();
            return handler.next(error);
          }

          error.requestOptions.extra['isRetry'] = true;

          try {
            final tokens = await _performTokenRefresh();
            if (tokens != null && tokens.accessToken.isNotEmpty) {
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } else {
              await _authSessionService.clearSession();
              return handler.next(error);
            }
          } catch (_) {
            await _authSessionService.clearSession();
            return handler.next(error);
          }
        },
      ),
    );
  }

  /// Test helper — clears the process-wide singleton between tests.
  static void resetSharedInstanceForTest() {
    _sharedInstance = null;
    _sharedRefreshCompleter = null;
  }

  bool _isSessionRevoked(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code'];
      if (code == 'SESSION_REVOKED') return true;
      final message = data['message'];
      if (message is String &&
          message.toLowerCase().contains('session revoked')) {
        return true;
      }
    }
    return false;
  }

  bool _isDeviceMismatch(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final data = error.response?.data;
    if (data is Map && data['code'] == 'DEVICE_MISMATCH') return true;
    return false;
  }

  Future<AuthTokens?> _performTokenRefresh() async {
    final inFlight = _sharedRefreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<AuthTokens?>();
    _sharedRefreshCompleter = completer;

    String? attemptedRefreshToken;
    try {
      final refreshToken = await _secureStorageService.getRefreshToken();
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      attemptedRefreshToken = refreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        return null;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
          extra: const {'isRetry': true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final tokens =
            AuthTokens.fromJson(response.data as Map<String, dynamic>);
        if (tokens.accessToken.isNotEmpty) {
          await _secureStorageService.saveAccessToken(tokens.accessToken);
        }
        if (tokens.refreshToken.isNotEmpty) {
          await _secureStorageService.saveRefreshToken(tokens.refreshToken);
        }
        completer.complete(tokens);
        return tokens;
      }

      completer.complete(null);
      return null;
    } catch (e) {
      // Sibling refresh may have already rotated + saved new tokens.
      final recovered = await _recoverTokensAfterRefreshRace(
        attemptedRefreshToken: attemptedRefreshToken,
        error: e,
      );
      if (recovered != null) {
        completer.complete(recovered);
        return recovered;
      }

      if (e is DioException && (_isSessionRevoked(e) || _isDeviceMismatch(e))) {
        await _authSessionService.clearSession();
      }
      completer.complete(null);
      return null;
    } finally {
      if (_sharedRefreshCompleter == completer) {
        _sharedRefreshCompleter = null;
      }
    }
  }

  /// When two refreshes race, the loser gets SESSION_REVOKED but storage may
  /// already hold the winner's new tokens — reuse them instead of logging out.
  Future<AuthTokens?> _recoverTokensAfterRefreshRace({
    required String? attemptedRefreshToken,
    required Object error,
  }) async {
    if (error is! DioException) return null;
    if (!_isSessionRevoked(error)) return null;

    final access = await _secureStorageService.getAccessToken();
    final refresh = await _secureStorageService.getRefreshToken();
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      return null;
    }

    // Tokens changed → another refresh already succeeded.
    if (attemptedRefreshToken != null && refresh != attemptedRefreshToken) {
      return AuthTokens(
        accessToken: access,
        refreshToken: refresh,
        expiresIn: 900,
      );
    }

    return null;
  }

  Dio get client => _dio;
}
