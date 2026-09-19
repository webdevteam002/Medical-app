import 'package:flutter/material.dart';
import 'theme_controller.dart';

class AppThemePalette {
  final Color primary;
  final Color primarySoft;
  final Color primaryDark;
  final Color secondary;
  final Color secondarySoft;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderSubtle;
  final Color borderHover;
  final bool isDark;

  const AppThemePalette({
    required this.primary,
    required this.primarySoft,
    required this.primaryDark,
    required this.secondary,
    required this.secondarySoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderSubtle,
    required this.borderHover,
    required this.isDark,
  });

  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary, secondary],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primarySoft, secondary],
      );

  LinearGradient get tealGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, secondarySoft],
      );

  LinearGradient get subtleCardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surface,
          isDark
              ? surface.withValues(alpha: 0.85)
              : surfaceMuted.withValues(alpha: 0.40),
        ],
      );

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.40)
              : const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  List<BoxShadow> get cardHoverShadow => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.60)
              : const Color(0xFF0B3A66).withValues(alpha: 0.10),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  List<BoxShadow> glowShadow([Color? customColor]) => [
        BoxShadow(
          color: (customColor ?? secondary).withValues(alpha: isDark ? 0.35 : 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  // Brand / clinical palette - compile-time constants for const widgets
  static const Color primaryColor = Color(0xFF0B3A66);
  static const Color primarySoft = Color(0xFF145A96);
  static const Color primaryDark = Color(0xFF072545);
  static const Color secondaryColor = Color(0xFF0D9488);
  static const Color secondarySoft = Color(0xFFCCFBF1);
  static const Color backgroundColor = Color(0xFFF4F7FB);
  static const Color surfaceColor = Colors.white;
  static const Color surfaceMuted = Color(0xFFEEF3F9);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color textPrimaryColor = Color(0xFF0F172A);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color textMutedColor = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);
  static const Color borderHover = Color(0xFFCBD5E1);

  // Semantic status colors
  static const Color successColor = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color warningColor = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color infoColor = Color(0xFF0284C7);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2Xl = 48.0;

  // Radii
  static const double borderRadiusSm = 12.0;
  static const double borderRadiusMd = 16.0;
  static const double borderRadiusLg = 20.0;
  static const double borderRadiusXl = 28.0;

  static const double buttonHeight = 52.0;

  // Static gradients & shadows
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryColor, secondaryColor],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primarySoft, secondaryColor],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, secondarySoft],
  );

  static const LinearGradient subtleCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceColor, Color(0x66EEF3F9)],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: Color(0x1A0B3A66),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glowShadow([Color? customColor]) => [
        BoxShadow(
          color: (customColor ?? secondaryColor).withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // 6 Predefined study palettes
  static const AppThemePalette _clinicalLightPalette = AppThemePalette(
    primary: Color(0xFF0B3A66),
    primarySoft: Color(0xFF145A96),
    primaryDark: Color(0xFF072545),
    secondary: Color(0xFF0D9488),
    secondarySoft: Color(0xFFCCFBF1),
    background: Color(0xFFF4F7FB),
    surface: Colors.white,
    surfaceMuted: Color(0xFFEEF3F9),
    surfaceSubtle: Color(0xFFF8FAFC),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    borderSubtle: Color(0xFFEDF2F7),
    borderHover: Color(0xFFCBD5E1),
    isDark: false,
  );

  static const AppThemePalette _midnightNavyPalette = AppThemePalette(
    primary: Color(0xFF38BDF8),
    primarySoft: Color(0xFF60A5FA),
    primaryDark: Color(0xFF0B132B),
    secondary: Color(0xFF14B8A6),
    secondarySoft: Color(0xFF134E4A),
    background: Color(0xFF0B132B),
    surface: Color(0xFF1C2541),
    surfaceMuted: Color(0xFF151E38),
    surfaceSubtle: Color(0xFF1E294B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    border: Color(0xFF2E3856),
    borderSubtle: Color(0xFF1E2746),
    borderHover: Color(0xFF3D4A70),
    isDark: true,
  );

  static const AppThemePalette _nordicFrostPalette = AppThemePalette(
    primary: Color(0xFF88C0D0),
    primarySoft: Color(0xFF81A1C1),
    primaryDark: Color(0xFF2E3440),
    secondary: Color(0xFFA3BE8C),
    secondarySoft: Color(0xFF3B4A3F),
    background: Color(0xFF242933),
    surface: Color(0xFF2E3440),
    surfaceMuted: Color(0xFF3B4252),
    surfaceSubtle: Color(0xFF434C5E),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFFD8DEE9),
    textMuted: Color(0xFF94A3B8),
    border: Color(0xFF4C566A),
    borderSubtle: Color(0xFF3B4252),
    borderHover: Color(0xFF5E6A82),
    isDark: true,
  );

  static const AppThemePalette _obsidianOledPalette = AppThemePalette(
    primary: Color(0xFF10B981),
    primarySoft: Color(0xFF34D399),
    primaryDark: Color(0xFF000000),
    secondary: Color(0xFF06B6D4),
    secondarySoft: Color(0xFF164E63),
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    surfaceMuted: Color(0xFF1A1A1A),
    surfaceSubtle: Color(0xFF242424),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    border: Color(0xFF27272A),
    borderSubtle: Color(0xFF18181B),
    borderHover: Color(0xFF3F3F46),
    isDark: true,
  );

  static const AppThemePalette _warmSepiaPalette = AppThemePalette(
    primary: Color(0xFF78350F),
    primarySoft: Color(0xFF92400E),
    primaryDark: Color(0xFF451A03),
    secondary: Color(0xFFD97706),
    secondarySoft: Color(0xFFFEF3C7),
    background: Color(0xFFF7F3E9),
    surface: Color(0xFFFFFDF8),
    surfaceMuted: Color(0xFFEFE9DA),
    surfaceSubtle: Color(0xFFFBF8F2),
    textPrimary: Color(0xFF2D231E),
    textSecondary: Color(0xFF715F54),
    textMuted: Color(0xFF9C8B80),
    border: Color(0xFFE5DDD0),
    borderSubtle: Color(0xFFEFE8DB),
    borderHover: Color(0xFFD3C6B3),
    isDark: false,
  );

  static const AppThemePalette _forestEmeraldPalette = AppThemePalette(
    primary: Color(0xFF10B981),
    primarySoft: Color(0xFF34D399),
    primaryDark: Color(0xFF062B22),
    secondary: Color(0xFF0D9488),
    secondarySoft: Color(0xFF134E4A),
    background: Color(0xFF07241C),
    surface: Color(0xFF0F3E33),
    surfaceMuted: Color(0xFF174F42),
    surfaceSubtle: Color(0xFF1E5D4F),
    textPrimary: Color(0xFFF0FDF4),
    textSecondary: Color(0xFFA7F3D0),
    textMuted: Color(0xFF6EE7B7),
    border: Color(0xFF1F5F50),
    borderSubtle: Color(0xFF164A3E),
    borderHover: Color(0xFF2E7B69),
    isDark: true,
  );

  static AppThemeMode _activeMode = AppThemeMode.clinicalLight;

  static void setThemeMode(AppThemeMode mode) {
    _activeMode = mode;
  }

  static AppThemeMode get activeMode => _activeMode;

  static AppThemePalette get currentPalette => paletteFor(_activeMode);

  static AppThemePalette paletteFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.clinicalLight:
        return _clinicalLightPalette;
      case AppThemeMode.midnightNavy:
        return _midnightNavyPalette;
      case AppThemeMode.nordicFrost:
        return _nordicFrostPalette;
      case AppThemeMode.obsidianOled:
        return _obsidianOledPalette;
      case AppThemeMode.warmSepia:
        return _warmSepiaPalette;
      case AppThemeMode.forestEmerald:
        return _forestEmeraldPalette;
    }
  }

  static TextTheme _buildTextTheme(AppThemePalette pal) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: pal.textPrimary,
        letterSpacing: -1.0,
        height: 1.15,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: pal.textPrimary,
        letterSpacing: -0.75,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: pal.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: pal.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: pal.textPrimary,
        letterSpacing: -0.2,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: pal.textPrimary,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: pal.textPrimary,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: pal.textSecondary,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: pal.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: pal.textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: pal.textMuted,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: pal.textPrimary,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: pal.textSecondary,
        letterSpacing: 0.1,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: pal.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  static ThemeData themeFor(AppThemeMode mode) {
    final pal = paletteFor(mode);
    final textTheme = _buildTextTheme(pal);

    final colorScheme = pal.isDark
        ? ColorScheme.dark(
            primary: pal.primary,
            onPrimary: Colors.black,
            secondary: pal.secondary,
            onSecondary: Colors.black,
            surface: pal.surface,
            onSurface: pal.textPrimary,
            error: errorColor,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: pal.primary,
            onPrimary: Colors.white,
            secondary: pal.secondary,
            onSecondary: Colors.white,
            surface: pal.surface,
            onSurface: pal.textPrimary,
            error: errorColor,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: pal.isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pal.background,
      cardColor: pal.surface,
      dividerColor: pal.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: pal.surface,
        foregroundColor: pal.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: pal.textPrimary,
        ),
        iconTheme: IconThemeData(color: pal.primary),
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: pal.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: pal.surface,
        elevation: 0,
        height: 72,
        indicatorColor: pal.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? pal.primary : pal.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? pal.primary : pal.textSecondary,
            size: 24,
          );
        }),
        surfaceTintColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      cardTheme: CardThemeData(
        color: pal.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          side: BorderSide(color: pal.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pal.primary,
          foregroundColor: pal.isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: pal.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            color: pal.isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pal.primary,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg),
          side: BorderSide(color: pal.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: pal.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pal.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pal.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
          borderSide: BorderSide(color: pal.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
          borderSide: BorderSide(color: pal.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
          borderSide: BorderSide(color: pal.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: pal.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: pal.isDark ? Colors.black : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: pal.primary,
      ),
      dividerTheme: DividerThemeData(
        color: pal.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pal.surfaceMuted,
        selectedColor: pal.secondarySoft,
        labelStyle: textTheme.bodySmall?.copyWith(color: pal.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: pal.border),
        ),
        side: BorderSide(color: pal.border),
      ),
    );
  }

  static ThemeData get lightTheme => themeFor(AppThemeMode.clinicalLight);
}
