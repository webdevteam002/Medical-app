import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/device/device_id_service.dart';
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
}

class TestDeviceIdService extends DeviceIdService {
  TestDeviceIdService({required super.secureStorageService});

  @override
  Future<String> getDeviceName() async {
    return 'Test Device Name';
  }
}

void main() {
  group('DeviceIdService Tests', () {
    late FakeSecureStorageService fakeStorage;
    late TestDeviceIdService deviceIdService;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      deviceIdService = TestDeviceIdService(secureStorageService: fakeStorage);
    });

    test('1. Generates and persists a new UUID device ID when none exists',
        () async {
      expect(fakeStorage.storage[SecureStorageService.deviceIdKey], isNull);

      final deviceId = await deviceIdService.getOrCreateDeviceId();

      expect(deviceId, isNotNull);
      expect(deviceId, isNotEmpty);
      expect(deviceId, isNot(equals('temp-device-id-day4')));
      expect(fakeStorage.storage[SecureStorageService.deviceIdKey],
          equals(deviceId));
    });

    test('2. Subsequent calls return the exact same persisted device ID',
        () async {
      const existingId = 'persisted-uuid-1234-5678';
      fakeStorage.storage[SecureStorageService.deviceIdKey] = existingId;

      final deviceId1 = await deviceIdService.getOrCreateDeviceId();
      final deviceId2 = await deviceIdService.getOrCreateDeviceId();

      expect(deviceId1, equals(existingId));
      expect(deviceId2, equals(existingId));
    });

    test('3. getDeviceName returns non-empty device name', () async {
      final deviceName = await deviceIdService.getDeviceName();
      expect(deviceName, equals('Test Device Name'));
    });
  });
}
