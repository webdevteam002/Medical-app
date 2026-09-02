import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/auth_session_service.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  final AuthSessionService? authSessionService;

  const SplashScreen({
    super.key,
    this.authSessionService,
  });

  Future<void> _handleNavigation(BuildContext context) async {
    final sessionService = authSessionService ?? AuthSessionService();
    try {
      final isAuth = await sessionService.isAuthenticated();
      if (context.mounted) {
        if (isAuth) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    } catch (_) {
      await sessionService.clearSession();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  size: 72,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  AppConstants.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                ElevatedButton(
                  onPressed: () => _handleNavigation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSm),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
