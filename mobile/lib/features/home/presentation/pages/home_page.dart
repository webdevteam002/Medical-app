import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/auth_session_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../exams/data/datasources/exams_remote_datasource.dart';
import '../../../study/data/datasources/study_remote_datasource.dart';
import '../widgets/exams_destination_view.dart';
import '../widgets/profile_destination_view.dart';
import '../widgets/study_destination_view.dart';

class HomePage extends StatefulWidget {
  final AuthSessionService? authSessionService;
  final StudyRemoteDataSource? studyRemoteDataSource;
  final ExamsRemoteDataSource? examsRemoteDataSource;

  const HomePage({
    super.key,
    this.authSessionService,
    this.studyRemoteDataSource,
    this.examsRemoteDataSource,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, activeThemeMode, _) {
        final List<Widget> destinations = [
          StudyDestinationView(
            studyRemoteDataSource: widget.studyRemoteDataSource,
          ),
          ExamsDestinationView(
            examsRemoteDataSource: widget.examsRemoteDataSource,
          ),
          ProfileDestinationView(
            authSessionService: widget.authSessionService,
          ),
        ];

        final isDesktopWidth = MediaQuery.of(context).size.width >= 600;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceColor,
            titleSpacing:
                isDesktopWidth ? AppTheme.spacingLg : AppTheme.spacingMd,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConstants.appName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondarySoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.secondaryColor
                                  .withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'MBBS · FCPS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Clinical Education & Exam Suite',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Quick AI Tutor button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Ask Clinical AI Assistant',
                  child: InkWell(
                    onTap: () {
                      try {
                        context.push('/ai-assistant');
                      } catch (_) {}
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI Tutor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;

              if (isDesktop) {
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: AppTheme.surfaceColor,
                      indicatorColor:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      minWidth: 80,
                      selectedLabelTextStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                      unselectedLabelTextStyle: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: Icon(Icons.menu_book_outlined,
                              color: AppTheme.textSecondaryColor),
                          selectedIcon: Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          label: const Text('Study'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.assignment_outlined,
                              color: AppTheme.textSecondaryColor),
                          selectedIcon: Icon(
                            Icons.assignment_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          label: const Text('Exams'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline,
                              color: AppTheme.textSecondaryColor),
                          selectedIcon: Icon(
                            Icons.person_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          label: const Text('Profile'),
                        ),
                      ],
                    ),
                    VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: destinations,
                      ),
                    ),
                  ],
                );
              }

              return IndexedStack(
                index: _selectedIndex,
                children: destinations,
              );
            },
          ),
          bottomNavigationBar: !isDesktopWidth
              ? Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: 'Study',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment_rounded),
                        label: 'Exams',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'Profile',
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
