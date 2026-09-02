import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/core/security/offline_encryption_service.dart';
import 'package:medstudy/core/security/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;
  late SecurityService securityService;

  setUp(() {
    log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.medstudy/security'),
      (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'enableSecureScreen' ||
            methodCall.method == 'disableSecureScreen') {
          return true;
        }
        return false;
      },
    );

    securityService = SecurityService();
  });

  group('Day 18 SecurityService & Day 20 AES-256-GCM AEAD Security Tests', () {
    test('1. enableSecureScreen invokes platform channel enableSecureScreen',
        () async {
      final result = await securityService.enableSecureScreen();

      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('enableSecureScreen'));
    });

    test('2. disableSecureScreen invokes platform channel disableSecureScreen',
        () async {
      final result = await securityService.disableSecureScreen();

      expect(result, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, equals('disableSecureScreen'));
    });

    test(
        '3. buildDynamicWatermark combines backend identity and formatted timestamp',
        () {
      final testTime = DateTime(2026, 9, 2, 12, 34, 56);
      final watermark = SecurityService.buildDynamicWatermark(
        backendWatermark: 'student@example.com · ID:abc123',
        timestamp: testTime,
      );

      expect(
        watermark,
        equals('student@example.com · ID:abc123 · 2026-09-02 12:34:56'),
      );
    });

    test(
        '4. AES-256-GCM round trip: encrypt and decrypt returns exact original bytes',
        () async {
      final cryptoService = OfflineEncryptionService();
      final originalBytes = [
        72,
        101,
        108,
        108,
        111,
        32,
        77,
        101,
        100,
        83,
        116,
        117,
        100,
        121
      ]; // "Hello MedStudy"

      final encrypted = await cryptoService.encryptBytes(originalBytes);
      expect(encrypted.length, equals(originalBytes.length + 1 + 12 + 16));

      final decrypted = await cryptoService.decryptBytes(encrypted);
      expect(decrypted, equals(originalBytes));
    });

    test('5. Ciphertext tampering causes AES-GCM authentication failure',
        () async {
      final cryptoService = OfflineEncryptionService();
      final originalBytes = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16
      ];

      final encrypted = await cryptoService.encryptBytes(originalBytes);
      final tampered = List<int>.from(encrypted);
      tampered[15] = tampered[15] ^ 0xFF; // Modify a byte in ciphertext

      expect(
        () async => await cryptoService.decryptBytes(tampered),
        throwsA(isA<Failure>()),
      );
    });

    test('6. Nonce tampering causes AES-GCM authentication failure', () async {
      final cryptoService = OfflineEncryptionService();
      final originalBytes = [10, 20, 30, 40, 50];

      final encrypted = await cryptoService.encryptBytes(originalBytes);
      final tamperedNonce = List<int>.from(encrypted);
      tamperedNonce[5] =
          tamperedNonce[5] ^ 0xFF; // Modify a byte in nonce (bytes 1..12)

      expect(
        () async => await cryptoService.decryptBytes(tamperedNonce),
        throwsA(isA<Failure>()),
      );
    });

    test(
        '7. Authentication tag tampering causes AES-GCM authentication failure',
        () async {
      final cryptoService = OfflineEncryptionService();
      final originalBytes = [10, 20, 30, 40, 50];

      final encrypted = await cryptoService.encryptBytes(originalBytes);
      final tamperedTag = List<int>.from(encrypted);
      tamperedTag[tamperedTag.length - 1] =
          tamperedTag[tamperedTag.length - 1] ^ 0xFF; // Modify last byte of tag

      expect(
        () async => await cryptoService.decryptBytes(tamperedTag),
        throwsA(isA<Failure>()),
      );
    });

    test('8. Decrypting with wrong key causes AES-GCM authentication failure',
        () async {
      final cryptoService = OfflineEncryptionService();
      final originalBytes = [100, 101, 102, 103];
      final key1 = List<int>.generate(32, (i) => i + 1);
      final key2 = List<int>.generate(32, (i) => i + 2);

      final encrypted = await cryptoService.encryptBytes(originalBytes,
          overrideKeyBytes: key1);

      expect(
        () async =>
            await cryptoService.decryptBytes(encrypted, overrideKeyBytes: key2),
        throwsA(isA<Failure>()),
      );
    });

    test('9. Unsupported container version byte throws safe failure', () async {
      final cryptoService = OfflineEncryptionService();
      final invalidPayload = [0x99] + List<int>.filled(30, 0);

      expect(
        () async => await cryptoService.decryptBytes(invalidPayload),
        throwsA(isA<Failure>()),
      );
    });

    test('10. Short or corrupt payload throws safe failure without crash',
        () async {
      final cryptoService = OfflineEncryptionService();
      final shortPayload = [0x01, 0x02, 0x03];

      expect(
        () async => await cryptoService.decryptBytes(shortPayload),
        throwsA(isA<Failure>()),
      );
    });
  });
}
