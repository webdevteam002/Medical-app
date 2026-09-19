import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_primary_button.dart';
import '../../data/models/exam_attempt_review_model.dart';
import '../../data/models/exam_submit_result_model.dart';
import '../../data/models/question_option_model.dart';

class ExamSubmitResultPage extends StatelessWidget {
  final String examTitle;
  final ExamSubmitResultModel result;

  const ExamSubmitResultPage({
    super.key,
    required this.examTitle,
    required this.result,
  });

  ExamAttemptReviewModel _toReviewModel() {
    return ExamAttemptReviewModel(
      id: result.attemptId,
      examTitle: examTitle,
      score: result.score,
      total: result.total,
      percentage: result.percentage,
      startedAt: DateTime.now(),
      completedAt: DateTime.now(),
      details: result.details
          .map(
            (d) => ExamReviewDetailModel(
              questionId: d.questionId,
              stem: d.stem,
              options: d.options
                  .map((o) => QuestionOptionModel(id: o.id, text: o.text))
                  .toList(),
              selectedOptionId: d.selectedOptionId,
              correctOptionId: d.correctOptionId,
              isCorrect: d.isCorrect,
              explanation: d.explanation,
              timeSpentSeconds: d.timeSpentSeconds,
            ),
          )
          .toList(),
    );
  }

  void _openFullReview(BuildContext context) {
    final attemptId = result.attemptId;
    if (attemptId.isEmpty && result.details.isEmpty) return;

    final initial = result.details.isNotEmpty ? _toReviewModel() : null;
    context.push(
      '/exams/attempts/${attemptId.isEmpty ? 'local' : attemptId}/review',
      extra: initial,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wrongCount = result.details.where((d) => !d.isCorrect).length;
    final pct = result.percentage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Exam Result'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MsCard(
                          padding: const EdgeInsets.all(AppTheme.spacingXl),
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: pct >= 50
                                      ? const LinearGradient(
                                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (pct >= 50 ? const Color(0xFF0D9488) : const Color(0xFFD97706))
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  pct >= 50
                                      ? Icons.emoji_events_rounded
                                      : Icons.analytics_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              Text(
                                examTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimaryColor,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      result.gradedBy == 'ai'
                                          ? Icons.auto_awesome_rounded
                                          : Icons.verified_rounded,
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      result.gradedBy == 'ai'
                                          ? 'Graded with MedStudy AI'
                                          : 'Exam Attempt Recorded',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXl),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _MetricTile(
                                        title: 'Score',
                                        value: '${result.score}/${result.total}',
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Container(
                                      height: 36,
                                      width: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    Expanded(
                                      child: _MetricTile(
                                        title: 'Percentage',
                                        value: '${pct.toStringAsFixed(1)}%',
                                        color: pct >= 50 ? AppTheme.successColor : AppTheme.warningColor,
                                      ),
                                    ),
                                    Container(
                                      height: 36,
                                      width: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    Expanded(
                                      child: _MetricTile(
                                        title: 'Incorrect',
                                        value: '$wrongCount',
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: AppTheme.tealGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Answer Review Breakdown',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        if (result.details.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No question details returned. Open Exam History to review later.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          )
                        else
                          ...result.details.asMap().entries.map((entry) {
                            return _QuestionReviewCard(
                              number: entry.key + 1,
                              detail: entry.value,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                if (result.attemptId.isNotEmpty ||
                    result.details.isNotEmpty) ...[
                  MsSecondaryButton(
                    label: 'Open full review',
                    icon: Icons.menu_book_rounded,
                    onPressed: () => _openFullReview(context),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                ],
                MsPrimaryButton(
                  label: 'Back to Home',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int number;
  final ExamQuestionResultDetail detail;

  const _QuestionReviewCard({
    required this.number,
    required this.detail,
  });

  String _optionLabel(String id) => id.toUpperCase();

  String _optionText(String? id) {
    if (id == null || id.isEmpty) return 'Not answered';
    final match = detail.options.where((o) => o.id == id);
    if (match.isEmpty) return _optionLabel(id);
    final opt = match.first;
    return '${_optionLabel(opt.id)}. ${opt.text}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        detail.isCorrect ? AppTheme.successColor : AppTheme.errorColor;
    final statusBg =
        detail.isCorrect ? AppTheme.successSoft : AppTheme.errorSoft;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(
            color: detail.isCorrect
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : AppTheme.errorColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Question $number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detail.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detail.isCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              detail.stem.isNotEmpty
                  ? detail.stem
                  : 'Question ${detail.questionId}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        detail.isCorrect ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your answer: ${_optionText(detail.selectedOptionId)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!detail.isCorrect) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Correct answer: ${_optionText(detail.correctOptionId)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (detail.explanation.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 15, color: AppTheme.secondaryColor),
                        const SizedBox(width: 5),
                        Text(
                          'Clinical Rationale',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.explanation,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
