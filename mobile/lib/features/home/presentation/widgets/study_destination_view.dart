import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
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
    context.push('/subjects/${year.slug}', extra: year.name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Library',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'Medical education years for ${AppConstants.appName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Offline Downloads',
                  icon: const Icon(Icons.download_for_offline_outlined,
                      color: AppTheme.primaryColor),
                  onPressed: () => context.push('/offline-materials'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchYears,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_years.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No study years available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Check back later for updated curriculum content.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton(
              onPressed: _fetchYears,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _years.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final year = _years[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingSm,
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                'Y${year.sortOrder}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              year.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: Text(
              'Slug: ${year.slug}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor),
            onTap: () => _onYearTap(year),
          ),
        );
      },
    );
  }
}
