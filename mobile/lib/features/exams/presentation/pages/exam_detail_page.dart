import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_gradient_header.dart';
import '../../../../core/widgets/ms_primary_button.dart';
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
            backgroundColor: AppTheme.errorColor,
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
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Exam Overview'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MsGradientHeader(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exam.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.exam.subjectName != null &&
                                  widget.exam.subjectName!.isNotEmpty)
                                MsMetaChip(
                                  icon: Icons.book_rounded,
                                  label: widget.exam.subjectName!,
                                  color: Colors.white,
                                  background:
                                      Colors.white.withValues(alpha: 0.16),
                                ),
                              if (widget.exam.yearName != null &&
                                  widget.exam.yearName!.isNotEmpty)
                                MsMetaChip(
                                  icon: Icons.school_rounded,
                                  label: widget.exam.yearName!,
                                  color: Colors.white,
                                  background:
                                      Colors.white.withValues(alpha: 0.16),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.timer_rounded,
                                  iconColor: AppTheme.warningColor,
                                  soft: AppTheme.warningSoft,
                                  title: 'Duration',
                                  value:
                                      '${widget.exam.durationMinutes} Minutes',
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.quiz_rounded,
                                  iconColor: AppTheme.primaryColor,
                                  soft: AppTheme.surfaceMuted,
                                  title: 'Questions',
                                  value:
                                      '${widget.exam.questionCount} Questions',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          MsCard(
                            elevated: false,
                            child: Column(
                              children: [
                                _buildInstructionTile(
                                  icon: Icons.access_alarm_rounded,
                                  text:
                                      'The countdown starts when you tap Start Exam and runs continuously.',
                                ),
                                const Divider(height: 24),
                                _buildInstructionTile(
                                  icon: Icons.lock_clock_rounded,
                                  text:
                                      'One active attempt at a time per exam.',
                                ),
                                const Divider(height: 24),
                                _buildInstructionTile(
                                  icon: Icons.fact_check_rounded,
                                  text:
                                      'Unanswered questions score zero — review before submit.',
                                ),
                                const Divider(height: 24),
                                _buildInstructionTile(
                                  icon: Icons.verified_user_rounded,
                                  text:
                                      'Session is verified with device binding.',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: MsPrimaryButton(
                label: _isStarting ? 'Starting Session...' : 'Start Exam',
                isLoading: _isStarting,
                icon: Icons.play_arrow_rounded,
                onPressed: _startExam,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color soft,
    required String title,
    required String value,
  }) {
    return MsCard(
      elevated: true,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionTile({
    required IconData icon,
    required String text,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 0),
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
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
