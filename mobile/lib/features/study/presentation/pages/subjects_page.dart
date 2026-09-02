import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/study_remote_datasource.dart';
import '../../data/models/subject_model.dart';

class SubjectsPage extends StatefulWidget {
  final String yearSlug;
  final String? yearName;
  final StudyRemoteDataSource? studyRemoteDataSource;

  const SubjectsPage({
    super.key,
    required this.yearSlug,
    this.yearName,
    this.studyRemoteDataSource,
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final StudyRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _dataSource.getSubjects(widget.yearSlug);
      if (mounted) {
        setState(() {
          _subjects = subjects;
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
              'Failed to load subjects. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSubjectTap(SubjectModel subject) {
    context.push('/subjects/${subject.id}/topics', extra: subject.name);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.yearName != null
        ? '${widget.yearName} Subjects'
        : 'Medical Subjects';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Subjects',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Year: ${widget.yearSlug}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
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
                onPressed: _fetchSubjects,
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

    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No subjects available for this year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Check back later for updated subject modules.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton(
              onPressed: _fetchSubjects,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _subjects.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final subject = _subjects[index];
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
              backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
              child: Text(
                'S${subject.sortOrder}',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              subject.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: Text(
              'Slug: ${subject.slug}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor),
            onTap: () => _onSubjectTap(subject),
          ),
        );
      },
    );
  }
}
