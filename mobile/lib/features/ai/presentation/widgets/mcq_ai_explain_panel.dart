import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/models/explain_mcq_response.dart';
import 'ai_sources_section.dart';

/// Student MCQ AI panel for exam review (AI-3).
/// Auto-loads the structured explanation when an answer is selected;
/// keeps an explicit action to ask follow-up questions about the MCQ.
class McqAiExplainPanel extends StatefulWidget {
  final String questionId;
  final String? selectedOptionId;
  final String selectedOptionLabel;
  final String selectedOptionText;
  final String correctOptionLabel;
  final String correctOptionText;
  final bool isCorrect;
  final AiRemoteDataSource? aiRemoteDataSource;

  /// Optional override for tests / hosts without GoRouter.
  final VoidCallback? onAskAboutQuestion;

  const McqAiExplainPanel({
    super.key,
    required this.questionId,
    required this.selectedOptionId,
    required this.selectedOptionLabel,
    required this.selectedOptionText,
    required this.correctOptionLabel,
    required this.correctOptionText,
    required this.isCorrect,
    this.aiRemoteDataSource,
    this.onAskAboutQuestion,
  });

  @override
  State<McqAiExplainPanel> createState() => _McqAiExplainPanelState();
}

class _McqAiExplainPanelState extends State<McqAiExplainPanel> {
  late final AiRemoteDataSource _ai;
  bool _loading = false;
  String? _error;
  String? _errorCode;
  ExplainMcqResponse? _result;

  @override
  void initState() {
    super.initState();
    _ai = widget.aiRemoteDataSource ?? AiRemoteDataSource();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestExplain();
    });
  }

  @override
  void didUpdateWidget(covariant McqAiExplainPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionId != widget.questionId ||
        oldWidget.selectedOptionId != widget.selectedOptionId) {
      setState(() {
        _loading = false;
        _error = null;
        _errorCode = null;
        _result = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestExplain();
      });
    }
  }

  Future<void> _requestExplain() async {
    if (_loading) return;
    final selectedId = widget.selectedOptionId;
    if (selectedId == null || selectedId.isEmpty) {
      setState(() {
        _error =
            'Select an answer during the exam to request an AI explanation.';
        _errorCode = 'NO_SELECTION';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final result = await _ai.explainMcq(
        questionId: widget.questionId,
        selectedOptionId: selectedId,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorCode = e.code;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _errorCode = 'NETWORK';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to request AI explanation.';
        _errorCode = 'UNKNOWN';
        _loading = false;
      });
    }
  }

  bool get _canRetry {
    if (_errorCode == 'AI_DISABLED' ||
        _errorCode == 'AI_QUOTA_EXCEEDED' ||
        _errorCode == 'NO_SELECTION') {
      return false;
    }
    return _error != null;
  }

  void _openAskAboutQuestion() {
    if (widget.onAskAboutQuestion != null) {
      widget.onAskAboutQuestion!();
      return;
    }
    final q = Uri.encodeQueryComponent(widget.questionId);
    context.push('/ai-assistant?questionId=$q');
  }

  @override
  Widget build(BuildContext context) {
    final unanswered = widget.selectedOptionId == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'AI Explanation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
          if (unanswered) ...[
            const SizedBox(height: AppTheme.spacingSm),
            const Text(
              'AI explanation is available after you select an answer.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
          if (_loading && _result == null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'Generating AI explanation…',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            const LinearProgressIndicator(key: Key('ai_explain_loading')),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _ErrorBanner(
              message: _error!,
              canRetry: _canRetry && !_loading,
              onRetry: _requestExplain,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _ExplanationBody(
              result: _result!,
              selectedLabel: widget.selectedOptionLabel,
              selectedText: widget.selectedOptionText,
              correctLabel: widget.correctOptionLabel,
              correctText: widget.correctOptionText,
              isCorrect: widget.isCorrect,
              onRefresh: _loading ? null : _requestExplain,
              loading: _loading,
            ),
          ],
          if (!unanswered) ...[
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('ask_ai_about_question_button'),
                onPressed: _openAskAboutQuestion,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Ask about this question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ai_explain_error'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningSoft,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimaryColor,
              height: 1.35,
            ),
          ),
          if (canRetry) ...[
            const SizedBox(height: AppTheme.spacingSm),
            TextButton.icon(
              key: const Key('ai_explain_retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExplanationBody extends StatelessWidget {
  final ExplainMcqResponse result;
  final String selectedLabel;
  final String selectedText;
  final String correctLabel;
  final String correctText;
  final bool isCorrect;
  final VoidCallback? onRefresh;
  final bool loading;

  const _ExplanationBody({
    required this.result,
    required this.selectedLabel,
    required this.selectedText,
    required this.correctLabel,
    required this.correctText,
    required this.isCorrect,
    required this.onRefresh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ai_explain_result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Your Answer',
          body: '$selectedLabel — $selectedText',
        ),
        _Section(
          title: 'Correct Answer',
          body: '$correctLabel — $correctText',
        ),
        if (!isCorrect &&
            result.whySelectedWrong != null &&
            result.whySelectedWrong!.isNotEmpty)
          _Section(
            title: 'Why Your Answer Is Wrong',
            body: result.whySelectedWrong!,
          ),
        _Section(
          title: isCorrect
              ? 'Why Your Answer Is Correct'
              : 'Why the Correct Answer Is Correct',
          body: result.whyCorrect,
        ),
        if (result.whyOtherOptions.isNotEmpty) ...[
          const Text(
            'Other Options',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...result.whyOtherOptions.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(
                '${o.option} — ${o.explanation}',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        _Section(title: 'Core Concept', body: result.concept),
        _Section(title: 'Exam Takeaway', body: result.examTakeaway),
        if (result.questionQuality != 'valid' &&
            (result.questionConcern?.isNotEmpty ?? false))
          Container(
            key: const Key('ai_quality_warning'),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.warningSoft,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            ),
            child: Text(
              'Note: ${result.questionConcern}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
                height: 1.35,
              ),
            ),
          ),
        if (result.citations.isNotEmpty) ...[
          AiSourcesSection(
            citations: result.citations,
            grounding: result.grounding,
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ] else ...[
          Text(
            'Grounding: ${result.grounding}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('ai_explain_again'),
            onPressed: onRefresh,
            child: Text(loading ? 'Refreshing…' : 'Refresh explanation'),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFE2E8F0);
    Color titleColor = AppTheme.textPrimaryColor;
    IconData? icon;

    if (title.contains('Takeaway')) {
      bg = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      titleColor = const Color(0xFF1E40AF);
      icon = Icons.emoji_events_outlined;
    } else if (title.contains('Concept')) {
      bg = const Color(0xFFF0FDFA);
      borderColor = const Color(0xFF99F6E4);
      titleColor = const Color(0xFF0F766E);
      icon = Icons.psychology_outlined;
    } else if (title.contains('Wrong')) {
      bg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      titleColor = const Color(0xFFB45309);
      icon = Icons.info_outline_rounded;
    } else if (title.contains('Correct')) {
      bg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      titleColor = const Color(0xFF15803D);
      icon = Icons.check_circle_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: titleColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
