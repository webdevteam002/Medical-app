import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/auth_session_service.dart';
import '../../../../core/theme/app_theme.dart';
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
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
            ),
          ],
        ),
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
                  indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded,
                          color: AppTheme.primaryColor),
                      label: Text('Study'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_rounded,
                          color: AppTheme.primaryColor),
                      label: Text('Exams'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded,
                          color: AppTheme.primaryColor),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(
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
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
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
  }
}
