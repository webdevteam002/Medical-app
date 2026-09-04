import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/exam_submit_result_model.dart';

class ExamSubmitResultPage extends StatelessWidget {
  final String examTitle;
  final ExamSubmitResultModel result;

  const ExamSubmitResultPage({
    super.key,
    required this.examTitle,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Result'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
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
                      children: [
                        const SizedBox(height: AppTheme.spacingLg),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          examTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        const Text(
                          'Exam Submitted Successfully',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusMd),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLg),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildResultMetric(
                                      context: context,
                                      title: 'Score',
                                      value:
                                          '${result.score} / ${result.total}',
                                      color: AppTheme.primaryColor,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    _buildResultMetric(
                                      context: context,
                                      title: 'Percentage',
                                      value:
                                          '${result.percentage.toStringAsFixed(1)}%',
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetric({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
