import 'dart:async';
import 'package:dio/dio.dart';
import '../../features/auth/data/models/auth_tokens.dart';
import '../config/app_config.dart';
import '../device/device_id_service.dart';
import '../storage/auth_session_service.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorageService;
  final DeviceIdService _deviceIdService;
  final AuthSessionService _authSessionService;

  Completer<AuthTokens?>? _refreshCompleter;

  ApiClient({
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

          if (!options.headers.containsKey('Authorization')) {
            final token = await _secureStorageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
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

          if (_isSessionRevoked(error)) {
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

  Future<AuthTokens?> _performTokenRefresh() async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<AuthTokens?>();

    try {
      final refreshToken = await _secureStorageService.getRefreshToken();
      final deviceId = await _deviceIdService.getOrCreateDeviceId();

      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout:
              const Duration(milliseconds: AppConfig.connectTimeoutMs),
          receiveTimeout:
              const Duration(milliseconds: AppConfig.receiveTimeoutMs),
          sendTimeout: const Duration(milliseconds: AppConfig.sendTimeoutMs),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
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
        _refreshCompleter!.complete(tokens);
        return tokens;
      } else {
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      if (e is DioException && _isSessionRevoked(e)) {
        await _authSessionService.clearSession();
      }
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Dio get client => _dio;
}
