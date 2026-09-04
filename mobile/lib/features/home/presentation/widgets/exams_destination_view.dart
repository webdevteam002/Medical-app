import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/data/datasources/exams_remote_datasource.dart';
import '../../../exams/data/models/exam_model.dart';

class ExamsDestinationView extends StatefulWidget {
  final ExamsRemoteDataSource? examsRemoteDataSource;
  final String? yearSlug;
  final String? subjectId;

  const ExamsDestinationView({
    super.key,
    this.examsRemoteDataSource,
    this.yearSlug,
    this.subjectId,
  });

  @override
  State<ExamsDestinationView> createState() => _ExamsDestinationViewState();
}

class _ExamsDestinationViewState extends State<ExamsDestinationView> {
  late final ExamsRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<ExamModel> _exams = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.examsRemoteDataSource ?? ExamsRemoteDataSource();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _dataSource.getExams(
        yearSlug: widget.yearSlug,
        subjectId: widget.subjectId,
      );
      if (mounted) {
        setState(() {
          _exams = list;
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
          _errorMessage = 'Failed to load published exams.';
          _isLoading = false;
        });
      }
    }
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QBank & Exams',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Medical exam preparation & self-assessment portal',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => context.push('/exams/history'),
                  icon: const Icon(Icons.history_rounded,
                      color: AppTheme.primaryColor),
                  tooltip: 'Exam Attempt History',
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
                    fontSize: 15, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchExams,
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

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_late_outlined,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No exams published yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Published mock exams and practice tests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: _fetchExams,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchExams,
      child: ListView.separated(
        itemCount: _exams.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final exam = _exams[index];

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
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.amber,
                ),
              ),
              title: Text(
                exam.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              subtitle: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (exam.subjectName != null &&
                      exam.subjectName!.isNotEmpty) ...[
                    Text(
                      exam.subjectName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•',
                        style: TextStyle(color: AppTheme.textSecondaryColor)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '${exam.durationMinutes} mins',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('•',
                      style: TextStyle(color: AppTheme.textSecondaryColor)),
                  const SizedBox(width: 6),
                  Text(
                    '${exam.questionCount} questions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondaryColor),
              onTap: () {
                context.push(
                  '/exams/${exam.id}/detail',
                  extra: exam,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
