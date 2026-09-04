import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/exams_remote_datasource.dart';
import '../../data/models/exam_attempt_review_model.dart';

class ExamReviewPage extends StatefulWidget {
  final String attemptId;
  final ExamsRemoteDataSource? examsRemoteDataSource;
  final ExamAttemptReviewModel? initialReview;

  const ExamReviewPage({
    super.key,
    required this.attemptId,
    this.examsRemoteDataSource,
    this.initialReview,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_review?.examTitle ?? 'Exam Review'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
            vertical: AppTheme.spacingSm,
          ),
          color: const Color(0xFFF1F5F9),
          child: Row(
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
              Text(
                'Score: ${_review!.score}/${_review!.total} (${_review!.percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
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
                            ? Colors.amber.withValues(alpha: 0.15)
                            : detail.isCorrect
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
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
                                ? Colors.amber.shade900
                                : detail.isCorrect
                                    ? Colors.green
                                    : Colors.red,
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
                                  ? Colors.amber.shade900
                                  : detail.isCorrect
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
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
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: AppTheme.primaryColor),
                            SizedBox(width: 6),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

    if (isCorrectOption) {
      tileBg = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green;
      trailingIcon =
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20);
    } else if (isSelected && !isCorrectOption) {
      tileBg = Colors.red.withValues(alpha: 0.1);
      borderColor = Colors.red;
      trailingIcon =
          const Icon(Icons.cancel_rounded, color: Colors.red, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          border: Border.all(
              color: borderColor, width: isCorrectOption || isSelected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCorrectOption
                  ? Colors.green
                  : isSelected
                      ? Colors.red
                      : const Color(0xFFF1F5F9),
              child: Text(
                optionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCorrectOption || isSelected
                      ? Colors.white
                      : AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCorrectOption || isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }
}
