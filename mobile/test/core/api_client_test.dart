import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/device/device_id_service.dart';
import 'package:medstudy/core/network/api_client.dart';
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

class FakeDeviceIdService extends DeviceIdService {
  final String fakeId;

  FakeDeviceIdService({
    this.fakeId = 'fake-device-uuid-1234',
    super.secureStorageService,
  });

  @override
  Future<String> getOrCreateDeviceId() async {
    return fakeId;
  }

  @override
  Future<String> getDeviceName() async {
    return 'Test Device';
  }
}

class Fake401HttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"statusCode":401,"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeSessionRevokedHttpClientAdapter implements HttpClientAdapter {
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    return ResponseBody.fromString(
      '{"statusCode":401,"code":"SESSION_REVOKED","message":"Session revoked. Log in again."}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient Day 9 Interceptor Tests', () {
    late FakeSecureStorageService fakeStorage;
    late FakeDeviceIdService fakeDeviceIdService;
    late AuthSessionService authSessionService;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      fakeDeviceIdService =
          FakeDeviceIdService(secureStorageService: fakeStorage);
      authSessionService =
          AuthSessionService(secureStorageService: fakeStorage);
    });

    test('1. Interceptor attaches Authorization Bearer and X-Device-Id headers',
        () async {
      fakeStorage.storage[SecureStorageService.accessTokenKey] =
          'token_abc_123';

      final dio = Dio();
      final apiClient = ApiClient(
        dio: dio,
        secureStorageService: fakeStorage,
        deviceIdService: fakeDeviceIdService,
        authSessionService: authSessionService,
      );

      String? authHeader;
      String? deviceHeader;

      apiClient.client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            authHeader = options.headers['Authorization'];
            deviceHeader = options.headers['X-Device-Id'];
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      try {
        await apiClient.client.get('/users/profile');
      } catch (_) {}

      expect(authHeader, equals('Bearer token_abc_123'));
      expect(deviceHeader, equals('fake-device-uuid-1234'));
    });

    test('2. 401 failure without refresh token clears session and rejects',
        () async {
      fakeStorage.storage[SecureStorageService.accessTokenKey] =
          'expired_token';

      final dio = Dio();
      dio.httpClientAdapter = Fake401HttpClientAdapter();

      final apiClient = ApiClient(
        dio: dio,
        secureStorageService: fakeStorage,
        deviceIdService: fakeDeviceIdService,
        authSessionService: authSessionService,
      );

      try {
        await apiClient.client.get('/users/profile');
      } catch (e) {
        expect(e, isA<DioException>());
      }

      expect(fakeStorage.storage[SecureStorageService.accessTokenKey], isNull);
    });
  });

  group('ApiClient Day 11 SESSION_REVOKED Tests', () {
    late FakeSecureStorageService fakeStorage;
    late FakeDeviceIdService fakeDeviceIdService;
    late AuthSessionService authSessionService;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      fakeDeviceIdService =
          FakeDeviceIdService(secureStorageService: fakeStorage);
      authSessionService =
          AuthSessionService(secureStorageService: fakeStorage);

      fakeStorage.storage[SecureStorageService.accessTokenKey] =
          'access_token_123';
      fakeStorage.storage[SecureStorageService.refreshTokenKey] =
          'refresh_token_456';
      fakeStorage.storage[SecureStorageService.deviceIdKey] =
          'fake-device-uuid-1234';
    });

    test('1. SESSION_REVOKED response clears tokens while preserving device ID',
        () async {
      final dio = Dio();
      final adapter = FakeSessionRevokedHttpClientAdapter();
      dio.httpClientAdapter = adapter;

      final apiClient = ApiClient(
        dio: dio,
        secureStorageService: fakeStorage,
        deviceIdService: fakeDeviceIdService,
        authSessionService: authSessionService,
      );

      try {
        await apiClient.client.get('/users/profile');
      } catch (e) {
        expect(e, isA<DioException>());
      }

      // Verify access & refresh tokens cleared
      expect(fakeStorage.storage[SecureStorageService.accessTokenKey], isNull);
      expect(fakeStorage.storage[SecureStorageService.refreshTokenKey], isNull);

      // Verify device_id PRESERVED
      expect(fakeStorage.storage[SecureStorageService.deviceIdKey],
          equals('fake-device-uuid-1234'));

      // Verify only 1 network call was made (no refresh attempt triggered)
      expect(adapter.callCount, equals(1));
    });

    test('2. Explicit logout clears tokens while preserving device ID',
        () async {
      await authSessionService.logout();

      expect(fakeStorage.storage[SecureStorageService.accessTokenKey], isNull);
      expect(fakeStorage.storage[SecureStorageService.refreshTokenKey], isNull);
      expect(fakeStorage.storage[SecureStorageService.deviceIdKey],
          equals('fake-device-uuid-1234'));
      expect(await authSessionService.isAuthenticated(), isFalse);
    });
  });
}
