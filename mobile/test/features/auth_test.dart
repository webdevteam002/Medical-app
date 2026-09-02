import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/device/device_id_service.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/core/storage/secure_storage_service.dart';
import 'package:medstudy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:medstudy/features/auth/data/models/auth_tokens.dart';
import 'package:medstudy/features/auth/presentation/pages/login_page.dart';
import 'package:medstudy/features/auth/presentation/pages/register_page.dart';

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
}

class FakeDeviceIdService extends DeviceIdService {
  final String fakeId;
  final String fakeName;
  final SecureStorageService _storage;

  FakeDeviceIdService({
    this.fakeId = 'fake-device-uuid-1234',
    this.fakeName = 'Test Device Name',
    super.secureStorageService,
  }) : _storage = secureStorageService ?? SecureStorageService();

  @override
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.getDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    await _storage.saveDeviceId(fakeId);
    return fakeId;
  }

  @override
  Future<String> getDeviceName() async {
    return fakeName;
  }
}

class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  final bool shouldFail;
  final String? errorMessage;
  final AuthTokens tokens;
  int loginCallCount = 0;
  int registerCallCount = 0;

  String? lastRegisterFullName;
  String? lastRegisterEmail;
  String? lastDeviceId;
  String? lastDeviceName;

  FakeAuthRemoteDataSource({
    this.shouldFail = false,
    this.errorMessage,
    this.tokens = const AuthTokens(
      accessToken: 'fake_access_token_123',
      refreshToken: 'fake_refresh_token_456',
      expiresIn: 900,
    ),
  });

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
  }) async {
    loginCallCount++;
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;

    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Invalid email or password');
    }
    return tokens;
  }

  @override
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String fullName,
    required String deviceId,
    required String deviceName,
  }) async {
    registerCallCount++;
    lastRegisterEmail = email;
    lastRegisterFullName = fullName;
    lastDeviceId = deviceId;
    lastDeviceName = deviceName;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Email already registered or invalid payload');
    }
    return tokens;
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('LoginPage Day 7 Tests', () {
    testWidgets('1. Login screen renders expected branding and fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const LoginPage()));

      expect(find.text('MedStudy'), findsOneWidget);
      expect(
          find.text('Sign in to your medical student portal'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('2. Successful login obtains real device ID and stores tokens',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource();
      final fakeStorage = FakeSecureStorageService();
      final deviceIdService =
          FakeDeviceIdService(secureStorageService: fakeStorage);

      await tester.pumpWidget(createWidgetUnderTest(
        LoginPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
          deviceIdService: deviceIdService,
        ),
      ));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.loginCallCount, equals(1));
      expect(fakeDataSource.lastDeviceId, equals('fake-device-uuid-1234'));
      expect(fakeStorage.storage[SecureStorageService.accessTokenKey],
          equals('fake_access_token_123'));
    });
  });

  group('RegisterPage Day 7 Integration Tests', () {
    testWidgets('1. Register screen renders expected title and fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RegisterPage()));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('2. Password mismatch shows validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RegisterPage()));

      await tester.enterText(
          find.byType(TextFormField).at(1), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password456');

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('3. Successful registration stores tokens and reuses device ID',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource();
      final fakeStorage = FakeSecureStorageService();
      final deviceIdService =
          FakeDeviceIdService(secureStorageService: fakeStorage);

      await tester.pumpWidget(createWidgetUnderTest(
        RegisterPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
          deviceIdService: deviceIdService,
        ),
      ));

      await tester.enterText(find.byType(TextFormField).at(0), 'Ali Khan');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.registerCallCount, equals(1));
      expect(fakeDataSource.lastRegisterEmail, equals('student@medstudy.org'));
      expect(fakeDataSource.lastRegisterFullName, equals('Ali Khan'));
      expect(fakeDataSource.lastDeviceId, equals('fake-device-uuid-1234'));
      expect(fakeStorage.storage[SecureStorageService.accessTokenKey],
          equals('fake_access_token_123'));
      expect(fakeStorage.storage[SecureStorageService.refreshTokenKey],
          equals('fake_refresh_token_456'));
    });

    testWidgets('4. Registration API error displays error banner',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Email already registered',
      );
      final fakeStorage = FakeSecureStorageService();
      final deviceIdService =
          FakeDeviceIdService(secureStorageService: fakeStorage);

      await tester.pumpWidget(createWidgetUnderTest(
        RegisterPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
          deviceIdService: deviceIdService,
        ),
      ));

      await tester.enterText(
          find.byType(TextFormField).at(1), 'existing@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.registerCallCount, equals(1));
      expect(fakeStorage.storage[SecureStorageService.accessTokenKey], isNull);
      expect(find.text('Email already registered'), findsOneWidget);
    });
  });
}
