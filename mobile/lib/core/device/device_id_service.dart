import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../storage/secure_storage_service.dart';

class DeviceIdService {
  final SecureStorageService _secureStorageService;
  final DeviceInfoPlugin _deviceInfoPlugin;
  final Uuid _uuid;

  DeviceIdService({
    SecureStorageService? secureStorageService,
    DeviceInfoPlugin? deviceInfoPlugin,
    Uuid? uuid,
  })  : _secureStorageService = secureStorageService ?? SecureStorageService(),
        _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
        _uuid = uuid ?? const Uuid();

  /// Obtains the stable MedStudy device identifier.
  /// If a device ID has already been persisted in [SecureStorageService],
  /// that exact ID is returned. Otherwise, a new UUID v4 is generated,
  /// persisted, and returned.
  Future<String> getOrCreateDeviceId() async {
    final existingId = await _secureStorageService.getDeviceId();
    if (existingId != null && existingId.trim().isNotEmpty) {
      return existingId.trim();
    }

    final newId = _uuid.v4();
    await _secureStorageService.saveDeviceId(newId);
    return newId;
  }

  /// Retrieves human-readable device info/model name via [DeviceInfoPlugin].
  /// Returns a safe fallback ('Flutter Mobile App') if platform retrieval fails.
  Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return '${webInfo.browserName.name} Web Client';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await _deviceInfoPlugin.androidInfo;
          final manufacturer = androidInfo.manufacturer;
          final model = androidInfo.model;
          if (manufacturer.isNotEmpty && model.isNotEmpty) {
            return '$manufacturer $model';
          }
          return model.isNotEmpty ? model : 'Android Device';

        case TargetPlatform.iOS:
          final iosInfo = await _deviceInfoPlugin.iosInfo;
          if (iosInfo.name.isNotEmpty) {
            return iosInfo.name;
          }
          return iosInfo.model.isNotEmpty ? iosInfo.model : 'iOS Device';

        case TargetPlatform.macOS:
          final macInfo = await _deviceInfoPlugin.macOsInfo;
          return macInfo.model.isNotEmpty ? macInfo.model : 'Mac Device';

        case TargetPlatform.windows:
          final winInfo = await _deviceInfoPlugin.windowsInfo;
          return winInfo.computerName.isNotEmpty
              ? winInfo.computerName
              : 'Windows PC';

        case TargetPlatform.linux:
          final linuxInfo = await _deviceInfoPlugin.linuxInfo;
          return linuxInfo.name.isNotEmpty ? linuxInfo.name : 'Linux Device';

        case TargetPlatform.fuchsia:
          return 'Fuchsia Device';
      }
    } catch (_) {
      // Fallback if platform check fails or running under test environment
    }

    return 'Flutter Mobile App';
  }
}
