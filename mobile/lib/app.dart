import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class MedStudyApp extends StatelessWidget {
  const MedStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, activeMode, _) {
        return MaterialApp.router(
          title: 'MedStudy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(activeMode),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
