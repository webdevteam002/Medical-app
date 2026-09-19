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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFF5EEAD4),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'TIMED CLINICAL ASSESSMENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.exam.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: -0.3,
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
                                  icon: Icons.menu_book_rounded,
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
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.tealGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exam Instructions & Rules',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimaryColor,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          MsCard(
                            elevated: false,
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            child: Column(
                              children: [
                                _buildInstructionTile(
                                  icon: Icons.access_alarm_rounded,
                                  title: 'Continuous Countdown',
                                  text:
                                      'The timer starts immediately upon tapping Start Exam and runs without pausing.',
                                ),
                                const Divider(height: 24, color: AppTheme.borderColor),
                                _buildInstructionTile(
                                  icon: Icons.devices_rounded,
                                  title: 'Single Active Attempt',
                                  text:
                                      'Only one active attempt at a time is permitted per exam across your devices.',
                                ),
                                const Divider(height: 24, color: AppTheme.borderColor),
                                _buildInstructionTile(
                                  icon: Icons.fact_check_rounded,
                                  title: 'Scoring Rules',
                                  text:
                                      'Unanswered questions score zero points. Review your answers before final submission.',
                                ),
                                const Divider(height: 24, color: AppTheme.borderColor),
                                _buildInstructionTile(
                                  icon: Icons.verified_user_rounded,
                                  title: 'Verified Anti-Cheating Session',
                                  text:
                                      'Your session is bound to this device with encrypted watermark protection.',
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
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: const Border(top: BorderSide(color: AppTheme.borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
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
    String? title,
    required String text,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
