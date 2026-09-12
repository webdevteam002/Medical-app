import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/auth_session_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_section_header.dart';

class ProfileDestinationView extends StatelessWidget {
  final AuthSessionService? authSessionService;

  const ProfileDestinationView({
    super.key,
    this.authSessionService,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final sessionService = authSessionService ?? AuthSessionService();
    await sessionService.logout();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MsSectionHeader(
              title: 'Student Profile',
              subtitle: 'Account & portal settings',
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    MsCard(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primarySoft,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Medical Student',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            'student@medstudy.org',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusSm),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Platform',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Flexible(
                                  child: Text(
                                    '${AppConstants.appName} v${AppConstants.appVersion}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    MsCard(
                      onTap: () => context.push('/subscriptions'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.secondarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subscription',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Manage your study access plan',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.buttonHeight,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.errorColor),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.errorColor.withValues(alpha: 0.45),
                          ),
                          overlayColor:
                              AppTheme.errorColor.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSm),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
