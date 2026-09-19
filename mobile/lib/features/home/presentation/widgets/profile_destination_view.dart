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
      try {
        context.go('/login');
      } catch (_) {}
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryDark,
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Medical Student',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
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
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: AppTheme.secondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Platform',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
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
                      key: const Key('profile_ai_assistant_card'),
                      onTap: () {
                        try {
                          context.push('/ai-assistant');
                        } catch (_) {}
                      },
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor
                                      .withValues(alpha: 0.14),
                                  AppTheme.secondaryColor
                                      .withValues(alpha: 0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Assistant',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ask about subjects, materials & concepts',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    MsCard(
                      onTap: () {
                        try {
                          context.push('/subscriptions');
                        } catch (_) {}
                      },
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.secondarySoft,
                                  AppTheme.secondaryColor
                                      .withValues(alpha: 0.14),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.secondaryColor
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                color: AppTheme.secondaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subscription',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your study access plan',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
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
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.errorColor.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusSm),
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
