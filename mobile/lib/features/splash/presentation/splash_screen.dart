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
                    Color(0xFF06182C),
                    Color(0xFF0B3A66),
                    Color(0xFF0D6964),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Subtle decorative background circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                    vertical: AppTheme.spacingLg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const MsBrandMark(light: true, size: 88),
                        const SizedBox(height: AppTheme.spacingLg),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'MBBS & FCPS Medical Learning Portal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          AppConstants.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        // Clinical feature highlights
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusMd),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildPill(
                                Icons.check_circle_outline_rounded,
                                'High-yield curriculum-aligned QBanks',
                              ),
                              const SizedBox(height: 8),
                              _buildPill(
                                Icons.timer_outlined,
                                'Timed mock exams with detailed review',
                              ),
                              const SizedBox(height: 8),
                              _buildPill(
                                Icons.picture_as_pdf_outlined,
                                'Encrypted offline study library',
                              ),
                            ],
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
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Get Started'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Encrypted & Device-Bound Clinical Portal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondarySoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
