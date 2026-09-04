import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
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
              const Text(
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _fetchAttempts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No past exam attempts found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Completed exam attempts and review logs will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: _fetchAttempts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
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
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                item.examTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      item.subjectName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•',
                        style: TextStyle(color: AppTheme.textSecondaryColor)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item.completedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${item.score}/${item.total}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              onTap: () {
                context.push('/exams/attempts/${item.id}/review');
              },
            ),
          );
        },
      ),
    );
  }
}
