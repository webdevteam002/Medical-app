import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ai/data/datasources/ai_remote_datasource.dart';
import '../../../ai/presentation/widgets/mcq_ai_explain_panel.dart';
import '../../data/datasources/exams_remote_datasource.dart';
import '../../data/models/exam_attempt_review_model.dart';
import '../../data/models/question_option_model.dart';

class ExamReviewPage extends StatefulWidget {
  final String attemptId;
  final ExamsRemoteDataSource? examsRemoteDataSource;
  final ExamAttemptReviewModel? initialReview;
  final AiRemoteDataSource? aiRemoteDataSource;

  const ExamReviewPage({
    super.key,
    required this.attemptId,
    this.examsRemoteDataSource,
    this.initialReview,
    this.aiRemoteDataSource,
  });

  @override
  State<ExamReviewPage> createState() => _ExamReviewPageState();
}

class _ExamReviewPageState extends State<ExamReviewPage> {
  late final ExamsRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  ExamAttemptReviewModel? _review;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.examsRemoteDataSource ?? ExamsRemoteDataSource();

    if (widget.initialReview != null) {
      _review = widget.initialReview;
      _isLoading = false;
    } else {
      _fetchReview();
    }
  }

  Future<void> _fetchReview() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final review = await _dataSource.getAttemptReview(widget.attemptId);
      if (mounted) {
        setState(() {
          _review = review;
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
          _errorMessage = 'Failed to load exam attempt review.';
          _isLoading = false;
        });
      }
    }
  }

  void _nextQuestion() {
    if (_review != null && _currentIndex < _review!.details.length - 1) {
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

  void _openPalette(BuildContext context) {
    if (_review == null || _review!.details.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
              Text(
                'Review Palette',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendBadge(
                      'Correct', Colors.green, Icons.check_circle_rounded),
                  _buildLegendBadge(
                      'Incorrect', Colors.red, Icons.cancel_rounded),
                  _buildLegendBadge('Unanswered', Colors.amber.shade800,
                      Icons.help_outline_rounded),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _review!.details.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = _review!.details[index];
                    final isCurrent = index == _currentIndex;
                    final isUnanswered = item.selectedOptionId == null;

                    Color tileBg = isUnanswered
                        ? Colors.amber.withValues(alpha: 0.15)
                        : item.isCorrect
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15);

                    Color textColor = isUnanswered
                        ? Colors.amber.shade900
                        : item.isCorrect
                            ? Colors.green.shade900
                            : Colors.red.shade900;

                    Border border = Border.all(
                      color: isCurrent
                          ? AppTheme.primaryColor
                          : const Color(0xFFE2E8F0),
                      width: isCurrent ? 2.5 : 1,
                    );

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
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSm),
                          border: border,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
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
  }

  Widget _buildLegendBadge(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  String _optionText(
    List<QuestionOptionModel> options,
    String? optionId, {
    String emptyLabel = '',
  }) {
    if (optionId == null) return emptyLabel;
    for (final opt in options) {
      if (opt.id == optionId) return opt.text;
    }
    return emptyLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_review?.examTitle ?? 'Exam Review'),
        actions: [
          if (_review != null)
            IconButton(
              onPressed: () => _openPalette(context),
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Review Palette',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchReview,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_review == null || _review!.details.isEmpty) {
      return const Center(
        child: Text('No question review details available.'),
      );
    }

    final detail = _review!.details[_currentIndex];
    final totalQuestions = _review!.details.length;
    final isUnanswered = detail.selectedOptionId == null;

    return Column(
      children: [
        // Top score bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, size: 13, color: AppTheme.primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      'Question ${_currentIndex + 1} of $totalQuestions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _review!.percentage >= 50
                      ? AppTheme.successSoft
                      : AppTheme.warningSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _review!.percentage >= 50
                        ? AppTheme.successColor.withValues(alpha: 0.3)
                        : AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Score: ${_review!.score}/${_review!.total} (${_review!.percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _review!.percentage >= 50
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnanswered
                            ? AppTheme.warningSoft
                            : detail.isCorrect
                                ? AppTheme.successSoft
                                : AppTheme.errorSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUnanswered
                                ? Icons.help_outline_rounded
                                : detail.isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                            size: 16,
                            color: isUnanswered
                                ? AppTheme.warningColor
                                : detail.isCorrect
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUnanswered
                                ? 'Unanswered'
                                : detail.isCorrect
                                    ? 'Correct Answer'
                                    : 'Incorrect Answer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUnanswered
                                  ? AppTheme.warningColor
                                  : detail.isCorrect
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  detail.stem,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                ...detail.options.map(
                  (opt) => _buildReviewOptionTile(
                    optionId: opt.id,
                    optionText: opt.text,
                    isSelected: opt.id == detail.selectedOptionId,
                    isCorrectOption: opt.id == detail.correctOptionId,
                  ),
                ),
                if (detail.explanation.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMd),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Explanation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          detail.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),
                McqAiExplainPanel(
                  key: ValueKey(
                    'ai-${detail.questionId}-${detail.selectedOptionId ?? 'none'}',
                  ),
                  questionId: detail.questionId,
                  selectedOptionId: detail.selectedOptionId,
                  selectedOptionLabel:
                      (detail.selectedOptionId ?? '—').toUpperCase(),
                  selectedOptionText: _optionText(
                    detail.options,
                    detail.selectedOptionId,
                    emptyLabel: 'No answer selected',
                  ),
                  correctOptionLabel: detail.correctOptionId.toUpperCase(),
                  correctOptionText: _optionText(
                    detail.options,
                    detail.correctOptionId,
                  ),
                  isCorrect: detail.isCorrect,
                  aiRemoteDataSource: widget.aiRemoteDataSource,
                ),
              ],
            ),
          ),
        ),
        // Navigation Bar
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
              ElevatedButton.icon(
                onPressed:
                    _currentIndex < totalQuestions - 1 ? _nextQuestion : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewOptionTile({
    required String optionId,
    required String optionText,
    required bool isSelected,
    required bool isCorrectOption,
  }) {
    final optionLabel = optionId.toUpperCase();

    Color tileBg = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Widget? trailingIcon;

    Widget? statusBadge;

    if (isCorrectOption && isSelected) {
      tileBg = const Color(0xFFF0FDF4);
      borderColor = AppTheme.successColor;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.successSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.successColor),
            SizedBox(width: 4),
            Text(
              'Your Answer (Correct)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      );
    } else if (isCorrectOption) {
      tileBg = const Color(0xFFF0FDF4);
      borderColor = AppTheme.successColor;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.successSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.successColor),
            SizedBox(width: 4),
            Text(
              'Correct Answer',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      );
    } else if (isSelected) {
      tileBg = const Color(0xFFFEF2F2);
      borderColor = AppTheme.errorColor;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.errorSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 12, color: AppTheme.errorColor),
            SizedBox(width: 4),
            Text(
              'Your Choice (Incorrect)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(
            color: borderColor,
            width: isCorrectOption || isSelected ? 1.8 : 1,
          ),
          boxShadow: (isCorrectOption || isSelected)
              ? [
                  BoxShadow(
                    color: (isCorrectOption ? AppTheme.successColor : AppTheme.errorColor)
                        .withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCorrectOption
                        ? AppTheme.successColor
                        : isSelected
                            ? AppTheme.errorColor
                            : AppTheme.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCorrectOption || isSelected
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCorrectOption || isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: AppTheme.textPrimaryColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (statusBadge != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: statusBadge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
