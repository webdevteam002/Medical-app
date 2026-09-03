import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.medstudy/security');

  final MethodChannel channel;

  SecurityService({MethodChannel? channel}) : channel = channel ?? _channel;

  Future<bool> enableSecureScreen() async {
    try {
      final bool? result =
          await channel.invokeMethod<bool>('enableSecureScreen');
      return result ?? false;
    } on MissingPluginException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disableSecureScreen() async {
    try {
      final bool? result =
          await channel.invokeMethod<bool>('disableSecureScreen');
      return result ?? false;
    } on MissingPluginException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  static String buildDynamicWatermark({
    String? backendWatermark,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    if (backendWatermark != null && backendWatermark.isNotEmpty) {
      return '$backendWatermark · $dateStr';
    }

    return 'Authenticated Student · $dateStr';
  }
}
