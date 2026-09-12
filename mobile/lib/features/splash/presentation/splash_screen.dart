import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/auth_session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ms_gradient_header.dart';

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
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071E36),
                    Color(0xFF0B3A66),
                    Color(0xFF115E59),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MsBrandMark(light: true, size: 84),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      SizedBox(
                        width: double.infinity,
                        height: AppTheme.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => _handleNavigation(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'MBBS · FCPS · Clinical exam prep',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
