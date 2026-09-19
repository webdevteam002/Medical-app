import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_theme.dart';

enum AppThemeMode {
  clinicalLight,
  midnightNavy,
  nordicFrost,
  obsidianOled,
  warmSepia,
  forestEmerald,
}

class AppThemeInfo {
  final AppThemeMode mode;
  final String name;
  final String badge;
  final String description;
  final bool isDark;
  final List<Color> previewColors;
  final IconData icon;

  const AppThemeInfo({
    required this.mode,
    required this.name,
    required this.badge,
    required this.description,
    required this.isDark,
    required this.previewColors,
    required this.icon,
  });
}

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _storageKey = 'medstudy_active_theme';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final ValueNotifier<AppThemeMode> currentTheme =
      ValueNotifier<AppThemeMode>(AppThemeMode.clinicalLight);

  static final List<AppThemeInfo> availableThemes = [
    const AppThemeInfo(
      mode: AppThemeMode.clinicalLight,
      name: 'Clinical Light',
      badge: 'Daylight Focus',
      description: 'Clean medical navy with crisp daylight contrast and clear diagram rendering.',
      isDark: false,
      previewColors: [
        Color(0xFFF4F7FB),
        Colors.white,
        Color(0xFF0D9488),
        Color(0xFF0B3A66),
      ],
      icon: Icons.light_mode_rounded,
    ),
    const AppThemeInfo(
      mode: AppThemeMode.midnightNavy,
      name: 'Midnight Navy',
      badge: 'Night Shift',
      description: 'Deep hospital navy canvas with glowing medical teal accents for night sessions.',
      isDark: true,
      previewColors: [
        Color(0xFF0B132B),
        Color(0xFF1C2541),
        Color(0xFF14B8A6),
        Color(0xFF38BDF8),
      ],
      icon: Icons.nightlight_round,
    ),
    const AppThemeInfo(
      mode: AppThemeMode.nordicFrost,
      name: 'Nordic Frost',
      badge: 'Anti-Glare',
      description: 'Arctic slate dark theme engineered to minimize eye strain during long study hours.',
      isDark: true,
      previewColors: [
        Color(0xFF2E3440),
        Color(0xFF3B4252),
        Color(0xFF88C0D0),
        Color(0xFF81A1C1),
      ],
      icon: Icons.ac_unit_rounded,
    ),
    const AppThemeInfo(
      mode: AppThemeMode.obsidianOled,
      name: 'Obsidian OLED',
      badge: 'True Black',
      description: 'Pure pitch black background with high-contrast emerald for zero screen bleed.',
      isDark: true,
      previewColors: [
        Color(0xFF000000),
        Color(0xFF121212),
        Color(0xFF10B981),
        Color(0xFF34D399),
      ],
      icon: Icons.dark_mode_rounded,
    ),
    const AppThemeInfo(
      mode: AppThemeMode.warmSepia,
      name: 'Warm Sepia',
      badge: 'Eye Comfort',
      description: 'Paper parchment reading palette that eliminates harsh blue-light fatigue.',
      isDark: false,
      previewColors: [
        Color(0xFFF7F3E9),
        Color(0xFFFFFDF7),
        Color(0xFFD97706),
        Color(0xFF78350F),
      ],
      icon: Icons.menu_book_rounded,
    ),
    const AppThemeInfo(
      mode: AppThemeMode.forestEmerald,
      name: 'Forest Emerald',
      badge: 'Calm Focus',
      description: 'Soothing clinical sage & forest tones designed to lower stress during exam prep.',
      isDark: true,
      previewColors: [
        Color(0xFF062B22),
        Color(0xFF0F3E33),
        Color(0xFF10B981),
        Color(0xFF059669),
      ],
      icon: Icons.spa_rounded,
    ),
  ];

  static Future<void> init() async {
    try {
      final savedValue = await _storage.read(key: _storageKey);
      if (savedValue != null) {
        final mode = AppThemeMode.values.firstWhere(
          (m) => m.name == savedValue,
          orElse: () => AppThemeMode.clinicalLight,
        );
        currentTheme.value = mode;
        AppTheme.setThemeMode(mode);
        return;
      }
    } catch (_) {}
    AppTheme.setThemeMode(AppThemeMode.clinicalLight);
  }

  static Future<void> setTheme(AppThemeMode mode) async {
    AppTheme.setThemeMode(mode);
    currentTheme.value = mode;
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {}
  }
}
