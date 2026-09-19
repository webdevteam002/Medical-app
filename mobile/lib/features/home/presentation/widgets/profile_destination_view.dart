import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/auth_session_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
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
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, activeMode, _) {
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
                                  gradient: LinearGradient(
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
                                      color: AppTheme.textPrimaryColor,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'student@medstudy.org',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingMd),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusSm),
                                  border:
                                      Border.all(color: AppTheme.borderColor),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: AppTheme.secondaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Platform',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Flexible(
                                      child: Text(
                                        '${AppConstants.appName} v${AppConstants.appVersion}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimaryColor,
                                            ),
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
                            child: Center(
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
                            child: Center(
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
                            child: Center(
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
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your study access plan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
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
                            child: Center(
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
                    _buildThemeSelectionSection(context),
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
  },
);
  }

  Widget _buildThemeSelectionSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, activeMode, _) {
        final themes = ThemeController.availableThemes;

        Widget content;
        if (isDesktop) {
          content = GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingMd,
              mainAxisSpacing: AppTheme.spacingMd,
              mainAxisExtent: 110,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              return _buildThemeCard(context, theme, activeMode == theme.mode);
            },
          );
        } else {
          content = Column(
            children: themes.map((theme) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: _buildThemeCard(context, theme, activeMode == theme.mode),
              );
            }).toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingLg),
            const MsSectionHeader(
              title: 'Study Themes & Appearance',
              subtitle: 'Select your preferred reading & exam aesthetic',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            content,
          ],
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppThemeInfo theme,
    bool isSelected,
  ) {
    return MsCard(
      onTap: () => ThemeController.setTheme(theme.mode),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      border: Border.all(
        color: isSelected ? AppTheme.secondaryColor : AppTheme.borderColor,
        width: isSelected ? 2.0 : 1.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.previewColors[0],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.secondaryColor.withValues(alpha: 0.60)
                    : AppTheme.borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.previewColors[1],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.previewColors[2],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  left: 7,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.previewColors[3],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  right: 7,
                  child: Icon(
                    theme.icon,
                    size: 13,
                    color: theme.previewColors[2],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        theme.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.secondaryColor
                                  : AppTheme.textPrimaryColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                            : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        theme.badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  theme.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.secondaryColor : AppTheme.borderColor,
                width: 1.8,
              ),
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
