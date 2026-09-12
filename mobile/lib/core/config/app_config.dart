import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// NestJS API base. Override at run time:
  /// `flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000/v1`
  ///
  /// Defaults:
  /// - desktop/web → localhost
  /// - Android emulator / other mobile → 10.0.2.2
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:3000/v1';
    }
    return 'http://10.0.2.2:3000/v1';
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int sendTimeoutMs = 15000;
}
