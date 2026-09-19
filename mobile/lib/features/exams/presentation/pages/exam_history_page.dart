import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_empty_state.dart';
import '../../data/datasources/exams_remote_datasource.dart';
import '../../data/models/exam_attempt_history_model.dart';

class ExamHistoryPage extends StatefulWidget {
  final ExamsRemoteDataSource? examsRemoteDataSource;

  const ExamHistoryPage({
    super.key,
    this.examsRemoteDataSource,
  });

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamsRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<ExamAttemptHistoryModel> _attempts = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.examsRemoteDataSource ?? ExamsRemoteDataSource();
    _fetchAttempts();
  }

  Future<void> _fetchAttempts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _dataSource.getExamAttempts();
      if (mounted) {
        setState(() {
          _attempts = list;
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
          _errorMessage = 'Failed to load exam history.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Attempt History'),
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
                'Past Exam Attempts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Review your completed mock exams and answer explanations',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MsErrorState(
        message: _errorMessage!,
        onRetry: _fetchAttempts,
      );
    }

    if (_attempts.isEmpty) {
      return MsEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'No past exam attempts found',
        message: 'Completed mock exams, scores, and answer explanations will be archived here.',
        actionLabel: 'Refresh',
        onAction: _fetchAttempts,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAttempts,
      child: ListView.separated(
        itemCount: _attempts.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final item = _attempts[index];
          final isPassed = item.percentage >= 50;

          return MsCard(
            onTap: () {
              context.push('/exams/attempts/${item.id}/review');
            },
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppTheme.successSoft
                        : AppTheme.warningSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPassed
                          ? AppTheme.successColor.withValues(alpha: 0.2)
                          : AppTheme.warningColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    isPassed
                        ? Icons.assignment_turned_in_rounded
                        : Icons.analytics_rounded,
                    color: isPassed
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.examTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.subjectName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.subjectName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatDate(item.completedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppTheme.successSoft
                            : AppTheme.warningSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPassed
                              ? AppTheme.successColor.withValues(alpha: 0.3)
                              : AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${item.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isPassed
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.score}/${item.total} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
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
