import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  final bool shouldFail;
  final String? errorMessage;
  final AuthTokens tokens;
  int callCount = 0;

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
  }) async {
    callCount++;
    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Invalid email or password');
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

  group('LoginPage Day 4 Integration & Unit Tests', () {
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

    testWidgets('2. Invalid/empty form does not call the API',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource();
      final fakeStorage = FakeSecureStorageService();

      await tester.pumpWidget(createWidgetUnderTest(
        LoginPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
        ),
      ));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(fakeDataSource.callCount, equals(0));
      expect(fakeStorage.storage, isEmpty);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('3. Successful login stores access token securely',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource();
      final fakeStorage = FakeSecureStorageService();

      await tester.pumpWidget(createWidgetUnderTest(
        LoginPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
        ),
      ));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump(); // Start async operation
      await tester.pumpAndSettle(); // Finish async operation

      expect(fakeDataSource.callCount, equals(1));
      expect(fakeStorage.storage[SecureStorageService.accessTokenKey],
          equals('fake_access_token_123'));
      expect(fakeStorage.storage[SecureStorageService.refreshTokenKey],
          equals('fake_refresh_token_456'));
    });

    testWidgets('4. Failed login shows appropriate error banner',
        (WidgetTester tester) async {
      final fakeDataSource = FakeAuthRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Invalid email or password',
      );
      final fakeStorage = FakeSecureStorageService();

      await tester.pumpWidget(createWidgetUnderTest(
        LoginPage(
          authRemoteDataSource: fakeDataSource,
          secureStorageService: fakeStorage,
        ),
      ));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.callCount, equals(1));
      expect(fakeStorage.storage, isEmpty);
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });

  group('RegisterPage Widget Tests', () {
    testWidgets('Register screen renders expected title and fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RegisterPage()));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('Password mismatch shows validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const RegisterPage()));

      await tester.enterText(
          find.byType(TextFormField).at(0), 'student@medstudy.org');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
