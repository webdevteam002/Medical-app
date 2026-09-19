import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_empty_state.dart';
import '../../../../core/widgets/ms_section_header.dart';
import '../../../study/data/datasources/study_remote_datasource.dart';
import '../../../study/data/models/year_model.dart';

class StudyDestinationView extends StatefulWidget {
  final StudyRemoteDataSource? studyRemoteDataSource;

  const StudyDestinationView({
    super.key,
    this.studyRemoteDataSource,
  });

  @override
  State<StudyDestinationView> createState() => _StudyDestinationViewState();
}

class _StudyDestinationViewState extends State<StudyDestinationView> {
  late final StudyRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<YearModel> _years = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final years = await _dataSource.getYears();
      if (mounted) {
        setState(() {
          _years = years;
          _isLoading = false;
        });
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load study years. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onYearTap(YearModel year) {
    try {
      context.push('/subjects/${year.slug}', extra: year.name);
    } catch (_) {}
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
            MsSectionHeader(
              title: 'Study Library',
              subtitle: 'Curriculum years for ${AppConstants.appName}',
              action: Row(
                children: [
                  _HeaderIconButton(
                    tooltip: 'Bookmarks',
                    icon: Icons.bookmark_outline_rounded,
                    onPressed: () {
                      try {
                        context.push('/bookmarks');
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    tooltip: 'Offline Downloads',
                    icon: Icons.download_for_offline_outlined,
                    onPressed: () {
                      try {
                        context.push('/offline-materials');
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MsErrorState(message: _errorMessage!, onRetry: _fetchYears);
    }

    if (_years.isEmpty) {
      return MsEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No study years available',
        message: 'Check back later for updated curriculum content.',
        actionLabel: 'Refresh',
        onAction: _fetchYears,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchYears,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _years.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final year = _years[index];

          // Curated medical accents per year
          final yearAccents = [
            const Color(0xFF0B3A66),
            const Color(0xFF0D9488),
            const Color(0xFF0284C7),
            const Color(0xFF4F46E5),
            const Color(0xFF059669),
          ];
          final accentColor = yearAccents[index % yearAccents.length];

          return MsCard(
            onTap: () => _onYearTap(year),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.16),
                        accentColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Y${year.sortOrder}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              year.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MBBS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Open subjects & materials',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
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
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
        ),
      ),
    );
  }
}
