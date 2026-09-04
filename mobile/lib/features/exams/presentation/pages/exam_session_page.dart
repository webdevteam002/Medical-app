import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/exams_remote_datasource.dart';
import '../../data/models/exam_start_session_model.dart';
import '../../data/models/submit_exam_dto.dart';

class ExamSessionPage extends StatefulWidget {
  final String examTitle;
  final ExamStartSessionModel session;
  final ExamsRemoteDataSource? examsRemoteDataSource;

  const ExamSessionPage({
    super.key,
    required this.examTitle,
    required this.session,
    this.examsRemoteDataSource,
  });

  @override
  State<ExamSessionPage> createState() => _ExamSessionPageState();
}

class _ExamSessionPageState extends State<ExamSessionPage>
    with WidgetsBindingObserver {
  late final ExamsRemoteDataSource _dataSource;
  int _currentIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  final Set<String> _flaggedQuestionIds = {};
  bool _isSubmitting = false;

  Timer? _timer;
  late DateTime _endTime;
  Duration _remainingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.examsRemoteDataSource ?? ExamsRemoteDataSource();
    WidgetsBinding.instance.addObserver(this);
    _initTimer();
  }

  void _initTimer() {
    _endTime = widget.session.startedAt.add(
      Duration(minutes: widget.session.durationMinutes),
    );
    _updateRemainingTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = _endTime.difference(now);

    setState(() {
      if (difference.isNegative || difference == Duration.zero) {
        _remainingDuration = Duration.zero;
        _timer?.cancel();
      } else {
        _remainingDuration = difference;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemainingTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  void _onOptionSelected(String questionId, String optionId) {
    if (_isSubmitting || !mounted) return;
    setState(() {
      _selectedAnswers[questionId] = optionId;
    });
  }

  void _toggleFlagQuestion(String questionId) {
    if (_isSubmitting || !mounted) return;
    setState(() {
      if (_flaggedQuestionIds.contains(questionId)) {
        _flaggedQuestionIds.remove(questionId);
      } else {
        _flaggedQuestionIds.add(questionId);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.session.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _submitExam() async {
    if (_isSubmitting || !mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    final answerDtos = widget.session.questions.map((q) {
      return SubmitAnswerDto(
        questionId: q.id,
        selectedOptionId: _selectedAnswers[q.id],
        timeSpentSeconds: 0,
      );
    }).toList();

    final dto = SubmitExamDto(answers: answerDtos);

    try {
      final result = await _dataSource.submitExam(
        widget.session.attemptId,
        dto,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        try {
          context.go(
            '/exams/results',
            extra: {
              'examTitle': widget.examTitle,
              'result': result,
            },
          );
        } catch (_) {
          // Fallback for test harness without GoRouter
        }
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit exam attempt.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSubmitConfirmationDialog(BuildContext context) {
    if (_isSubmitting) return;

    final totalQuestions = widget.session.questions.length;
    final answeredCount = _selectedAnswers.length;
    final flaggedCount = _flaggedQuestionIds.length;
    final unansweredCount = totalQuestions - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Submit Exam?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to finish and submit your exam answers?',
                style:
                    TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                      label: 'Answered Questions:',
                      value: '$answeredCount / $totalQuestions',
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      icon: Icons.flag_rounded,
                      color: Colors.orange,
                      label: 'Marked for Review:',
                      value: '$flaggedCount',
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      icon: Icons.circle_outlined,
                      color: AppTheme.textSecondaryColor,
                      label: 'Unanswered Questions:',
                      value: '$unansweredCount',
                    ),
                  ],
                ),
              ),
              if (unansweredCount > 0) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Warning: You have $unansweredCount unanswered question(s). Unanswered questions count as zero.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _submitExam();
                    },
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_isSubmitting ? 'Submitting...' : 'Confirm Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondaryColor)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _openQuestionPalette(BuildContext context) {
    final totalQuestions = widget.session.questions.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final answeredCount = _selectedAnswers.length;
            final flaggedCount = _flaggedQuestionIds.length;
            final unansweredCount = totalQuestions - answeredCount;

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question Palette',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendBadge(
                        label: 'Answered ($answeredCount)',
                        color: Colors.green,
                        icon: Icons.check_circle_rounded,
                      ),
                      _buildLegendBadge(
                        label: 'Flagged ($flaggedCount)',
                        color: Colors.orange,
                        icon: Icons.flag_rounded,
                      ),
                      _buildLegendBadge(
                        label: 'Unanswered ($unansweredCount)',
                        color: AppTheme.textSecondaryColor,
                        icon: Icons.circle_outlined,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: GridView.builder(
                      itemCount: totalQuestions,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final question = widget.session.questions[index];
                        final isCurrent = index == _currentIndex;
                        final isAnswered =
                            _selectedAnswers.containsKey(question.id);
                        final isFlagged =
                            _flaggedQuestionIds.contains(question.id);

                        Color tileBg = const Color(0xFFF1F5F9);
                        Color textColor = AppTheme.textPrimaryColor;
                        Border border =
                            Border.all(color: const Color(0xFFE2E8F0));

                        if (isCurrent) {
                          border = Border.all(
                            color: AppTheme.primaryColor,
                            width: 2.5,
                          );
                        }

                        if (isAnswered) {
                          tileBg = Colors.green.withValues(alpha: 0.15);
                          textColor = Colors.green.shade800;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSm),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tileBg,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusSm),
                              border: border,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                if (isFlagged)
                                  const Positioned(
                                    top: 3,
                                    right: 3,
                                    child: Icon(
                                      Icons.flag_rounded,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.examTitle),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No questions available in this exam.'),
        ),
      );
    }

    final currentQuestion = widget.session.questions[_currentIndex];
    final totalQuestions = widget.session.questions.length;
    final selectedOptionId = _selectedAnswers[currentQuestion.id];
    final isFlagged = _flaggedQuestionIds.contains(currentQuestion.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openQuestionPalette(context),
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
            tooltip: 'Question Palette',
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingMd),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _remainingDuration.inMinutes < 5
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 16,
                      color: _remainingDuration.inMinutes < 5
                          ? Colors.yellow
                          : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_remainingDuration),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _remainingDuration.inMinutes < 5
                            ? Colors.yellow
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (totalQuestions > 0)
                  ? (_currentIndex + 1) / totalQuestions
                  : 0,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppTheme.primaryColor,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of $totalQuestions',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _toggleFlagQuestion(currentQuestion.id),
                              icon: Icon(
                                isFlagged
                                    ? Icons.flag_rounded
                                    : Icons.flag_outlined,
                                color: isFlagged
                                    ? Colors.orange
                                    : AppTheme.textSecondaryColor,
                                size: 20,
                              ),
                              tooltip: isFlagged
                                  ? 'Unflag Question'
                                  : 'Flag for Review',
                            ),
                            Text(
                              _selectedAnswers.containsKey(currentQuestion.id)
                                  ? 'Answered'
                                  : 'Unanswered',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedAnswers
                                        .containsKey(currentQuestion.id)
                                    ? Colors.green
                                    : AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      currentQuestion.stem,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    ...currentQuestion.options.map(
                      (option) => _buildOptionTile(
                        questionId: currentQuestion.id,
                        optionId: option.id,
                        optionText: option.text,
                        isSelected: selectedOptionId == option.id,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? _previousQuestion : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Previous'),
                  ),
                  if (_currentIndex < totalQuestions - 1)
                    ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _showSubmitConfirmationDialog(context),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label:
                          Text(_isSubmitting ? 'Submitting...' : 'Submit Exam'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String questionId,
    required String optionId,
    required String optionText,
    required bool isSelected,
  }) {
    final optionLabel = optionId.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onOptionSelected(questionId, optionId),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFF1F5F9),
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
