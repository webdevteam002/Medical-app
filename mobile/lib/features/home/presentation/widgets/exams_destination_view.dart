import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ExamsDestinationView extends StatelessWidget {
  const ExamsDestinationView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QBank & Exams',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Medical exam preparation & self-assessment portal',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 64,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Practice Exams & Question Bank',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg),
                        child: Text(
                          'Test your knowledge with practice questions, timed mock exams, and instant performance analysis.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
