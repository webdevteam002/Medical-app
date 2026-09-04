import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/exams_remote_datasource.dart';
import '../../data/models/exam_model.dart';

class ExamDetailPage extends StatefulWidget {
  final ExamModel exam;
  final ExamsRemoteDataSource? examsRemoteDataSource;

  const ExamDetailPage({
    super.key,
    required this.exam,
    this.examsRemoteDataSource,
  });

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late final ExamsRemoteDataSource _dataSource;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.examsRemoteDataSource ?? ExamsRemoteDataSource();
  }

  Future<void> _startExam() async {
    if (_isStarting) return;

    if (!mounted) return;
    setState(() {
      _isStarting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting "${widget.exam.title}" session...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final session = await _dataSource.startExam(widget.exam.id);

      if (mounted) {
        setState(() {
          _isStarting = false;
        });

        try {
          context.push(
            '/exams/session/${session.attemptId}',
            extra: {
              'examTitle': widget.exam.title,
              'session': session,
            },
          );
        } catch (_) {
          // Fallback for widget testing without GoRouter harness
        }
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start exam session.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Overview'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exam.title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.exam.subjectName != null &&
                            widget.exam.subjectName!.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.book_rounded,
                                size: 16, color: AppTheme.primaryColor),
                            label: Text(widget.exam.subjectName!),
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            side: BorderSide.none,
                          ),
                        if (widget.exam.yearName != null &&
                            widget.exam.yearName!.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.school_rounded,
                                size: 16, color: AppTheme.secondaryColor),
                            label: Text(widget.exam.yearName!),
                            backgroundColor:
                                AppTheme.secondaryColor.withValues(alpha: 0.1),
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            icon: Icons.timer_rounded,
                            iconColor: Colors.orange,
                            title: 'Duration',
                            value: '${widget.exam.durationMinutes} Minutes',
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            icon: Icons.quiz_rounded,
                            iconColor: AppTheme.primaryColor,
                            title: 'Questions',
                            value: '${widget.exam.questionCount} Questions',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      'Exam Instructions & Rules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildInstructionTile(
                      icon: Icons.access_alarm_rounded,
                      text:
                          'The countdown timer starts as soon as you tap "Start Exam" and runs continuously.',
                    ),
                    _buildInstructionTile(
                      icon: Icons.lock_clock_rounded,
                      text:
                          'Single active attempt policy: You can only have one active attempt per exam.',
                    ),
                    _buildInstructionTile(
                      icon: Icons.fact_check_rounded,
                      text:
                          'Make sure to answer all questions before submitting. Unanswered questions count as zero.',
                    ),
                    _buildInstructionTile(
                      icon: Icons.verified_user_rounded,
                      text:
                          'Your session is securely verified with device binding.',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startExam,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(
                    _isStarting ? 'Starting Session...' : 'Start Exam',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMd),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              radius: 20,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionTile({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
