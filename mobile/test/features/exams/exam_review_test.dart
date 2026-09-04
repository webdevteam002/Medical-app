import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/features/exams/data/models/exam_attempt_review_model.dart';
import 'package:medstudy/features/exams/data/models/question_option_model.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_review_page.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 51 Exam Review Mode Unit & Widget Tests', () {
    test(
        '1. ExamAttemptReviewModel parses exact NestJS response JSON correctly',
        () {
      final json = {
        'id': 'att_123',
        'examTitle': 'Anatomy Midterm Mock Exam 2026',
        'score': 18,
        'total': 20,
        'percentage': 90.0,
        'startedAt': '2026-09-03T09:00:00.000Z',
        'completedAt': '2026-09-03T09:45:00.000Z',
        'details': [
          {
            'questionId': 'q1',
            'stem':
                'Which artery supplies the anterior compartment of the thigh?',
            'options': [
              {'id': 'a', 'text': 'Femoral artery'},
              {'id': 'b', 'text': 'Obturator artery'},
            ],
            'selectedOptionId': 'a',
            'correctOptionId': 'a',
            'isCorrect': true,
            'explanation': 'The femoral artery supplies the anterior thigh.',
            'timeSpentSeconds': 15,
          },
        ],
      };

      final review = ExamAttemptReviewModel.fromJson(json);

      expect(review.id, equals('att_123'));
      expect(review.examTitle, equals('Anatomy Midterm Mock Exam 2026'));
      expect(review.score, equals(18));
      expect(review.total, equals(20));
      expect(review.percentage, equals(90.0));
      expect(review.details.length, equals(1));
      expect(review.details.first.isCorrect, isTrue);
      expect(review.details.first.explanation,
          equals('The femoral artery supplies the anterior thigh.'));
    });

    testWidgets(
        '2. ExamReviewPage renders stem, options with correct/incorrect highlighting, and explanation',
        (WidgetTester tester) async {
      final review = ExamAttemptReviewModel(
        id: 'att_101',
        examTitle: 'Physiology Final Exam',
        score: 1,
        total: 2,
        percentage: 50.0,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        details: const [
          ExamReviewDetailModel(
            questionId: 'q1',
            stem: 'What is the primary action of the biceps brachii?',
            options: [
              QuestionOptionModel(
                  id: 'a', text: 'Forearm supination & flexion'),
              QuestionOptionModel(id: 'b', text: 'Elbow extension'),
            ],
            selectedOptionId: 'a',
            correctOptionId: 'a',
            isCorrect: true,
            explanation:
                'Biceps brachii is a powerful supinator and flexor of the forearm.',
          ),
          ExamReviewDetailModel(
            questionId: 'q2',
            stem: 'Which cell produces insulin?',
            options: [
              QuestionOptionModel(id: 'a', text: 'Alpha cells'),
              QuestionOptionModel(id: 'b', text: 'Beta cells'),
            ],
            selectedOptionId: 'a',
            correctOptionId: 'b',
            isCorrect: false,
            explanation: 'Beta cells of the pancreatic islets secrete insulin.',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamReviewPage(
          attemptId: 'att_101',
          initialReview: review,
        ),
      ));

      expect(find.text('Physiology Final Exam'), findsOneWidget);
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('Correct Answer'), findsOneWidget);
      expect(find.text('What is the primary action of the biceps brachii?'),
          findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(
          find.text(
              'Biceps brachii is a powerful supinator and flexor of the forearm.'),
          findsOneWidget);
    });

    testWidgets(
        '3. Navigating to Next question displays incorrect status & explanation',
        (WidgetTester tester) async {
      final review = ExamAttemptReviewModel(
        id: 'att_101',
        examTitle: 'Physiology Final Exam',
        score: 1,
        total: 2,
        percentage: 50.0,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        details: const [
          ExamReviewDetailModel(
            questionId: 'q1',
            stem: 'Stem 1',
            options: [QuestionOptionModel(id: 'a', text: 'Opt A')],
            selectedOptionId: 'a',
            correctOptionId: 'a',
            isCorrect: true,
            explanation: 'Explanation 1',
          ),
          ExamReviewDetailModel(
            questionId: 'q2',
            stem: 'Which cell produces insulin?',
            options: [
              QuestionOptionModel(id: 'a', text: 'Alpha cells'),
              QuestionOptionModel(id: 'b', text: 'Beta cells'),
            ],
            selectedOptionId: 'a',
            correctOptionId: 'b',
            isCorrect: false,
            explanation: 'Beta cells of the pancreatic islets secrete insulin.',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamReviewPage(
          attemptId: 'att_101',
          initialReview: review,
        ),
      ));

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(find.text('Incorrect Answer'), findsOneWidget);
      expect(find.text('Which cell produces insulin?'), findsOneWidget);
      expect(find.text('Beta cells of the pancreatic islets secrete insulin.'),
          findsOneWidget);
    });

    testWidgets('4. Handles unanswered question state gracefully',
        (WidgetTester tester) async {
      final review = ExamAttemptReviewModel(
        id: 'att_101',
        examTitle: 'Physiology Final Exam',
        score: 0,
        total: 1,
        percentage: 0.0,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        details: const [
          ExamReviewDetailModel(
            questionId: 'q1',
            stem: 'Unanswered Question Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Opt A'),
              QuestionOptionModel(id: 'b', text: 'Opt B'),
            ],
            selectedOptionId: null,
            correctOptionId: 'b',
            isCorrect: false,
            explanation: 'Unanswered question explanation.',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamReviewPage(
          attemptId: 'att_101',
          initialReview: review,
        ),
      ));

      expect(find.text('Unanswered'), findsOneWidget);
      expect(find.text('Unanswered Question Stem'), findsOneWidget);
    });
  });
}
