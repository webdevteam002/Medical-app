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
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: pct >= 50
                                      ? AppTheme.successSoft
                                      : AppTheme.warningSoft,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Icon(
                                  pct >= 50
                                      ? Icons.emoji_events_rounded
                                      : Icons.insights_rounded,
                                  size: 40,
                                  color: pct >= 50
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                examTitle,
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),
                              Text(
                                result.gradedBy == 'ai'
                                    ? 'Graded with AI explanations'
                                    : 'Submitted successfully',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'Score',
                                      value: '${result.score}/${result.total}',
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'Percent',
                                      value: '${pct.toStringAsFixed(1)}%',
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MetricTile(
                                      title: 'Wrong',
                                      value: '$wrongCount',
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),
                        Text(
                          'Answer review',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        if (result.details.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No question details returned. Open Exam History to review later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor),
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
          style: const TextStyle(
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
      child: MsCard(
      elevated: false,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q$number',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detail.isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            detail.stem.isNotEmpty
                ? detail.stem
                : 'Question ${detail.questionId}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Your answer: ${_optionText(detail.selectedOptionId)}',
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!detail.isCorrect) ...[
            const SizedBox(height: 4),
            Text(
              'Correct answer: ${_optionText(detail.correctOptionId)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (detail.explanation.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explanation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.explanation,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
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
