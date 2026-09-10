class AppConfig {
  AppConfig._();

  /// NestJS API base. Override at run time:
  /// `flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int sendTimeoutMs = 15000;
}
