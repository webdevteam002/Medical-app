import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_empty_state.dart';
import '../../../../core/widgets/ms_gradient_header.dart';
import '../../../../core/widgets/ms_section_header.dart';
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
              title: 'QBank & Exams',
              subtitle: 'Timed mocks and self-assessment',
              action: _HistoryButton(
                onPressed: () => context.push('/exams/history'),
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
      return MsErrorState(message: _errorMessage!, onRetry: _fetchExams);
    }

    if (_exams.isEmpty) {
      return MsEmptyState(
        icon: Icons.assignment_late_outlined,
        title: 'No exams published yet',
        message: 'Published mock exams and practice tests will appear here.',
        actionLabel: 'Refresh',
        onAction: _fetchExams,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchExams,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        itemCount: _exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return MsCard(
            onTap: () {
              context.push('/exams/${exam.id}/detail', extra: exam);
            },
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (exam.subjectName != null &&
                              exam.subjectName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              exam.subjectName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
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
                const SizedBox(height: AppTheme.spacingMd),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MsMetaChip(
                      icon: Icons.timer_outlined,
                      label: '${exam.durationMinutes} min',
                    ),
                    MsMetaChip(
                      icon: Icons.help_outline_rounded,
                      label: '${exam.questionCount} questions',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HistoryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exam Attempt History',
      child: Material(
        color: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.history_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
