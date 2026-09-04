import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:medstudy/features/exams/data/models/exam_question_model.dart';
import 'package:medstudy/features/exams/data/models/exam_start_session_model.dart';
import 'package:medstudy/features/exams/data/models/exam_submit_result_model.dart';
import 'package:medstudy/features/exams/data/models/question_option_model.dart';
import 'package:medstudy/features/exams/data/models/submit_exam_dto.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_session_page.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_submit_result_page.dart';

class FakeSubmitExamsRemoteDataSource extends ExamsRemoteDataSource {
  final bool shouldFail;
  final String? errorMessage;
  int submitExamCallCount = 0;
  String? lastAttemptId;
  SubmitExamDto? lastDto;

  FakeSubmitExamsRemoteDataSource({
    this.shouldFail = false,
    this.errorMessage,
  });

  @override
  Future<ExamSubmitResultModel> submitExam(
    String attemptId,
    SubmitExamDto dto,
  ) async {
    submitExamCallCount++;
    lastAttemptId = attemptId;
    lastDto = dto;

    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Failed to submit exam attempt.');
    }

    return const ExamSubmitResultModel(
      score: 1,
      total: 1,
      percentage: 100.0,
      details: [
        ExamQuestionResultDetail(
          questionId: 'q1',
          selectedOptionId: 'a',
          correctOptionId: 'a',
          isCorrect: true,
          explanation: 'Correct explanation',
        ),
      ],
    );
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 48-49 Exam Submission & Results Unit & Widget Tests', () {
    test('1. ExamSubmitResultModel parses exact NestJS response JSON correctly',
        () {
      final json = {
        'score': 18,
        'total': 20,
        'percentage': 90.0,
        'details': [
          {
            'questionId': 'q_1',
            'selectedOptionId': 'a',
            'correctOptionId': 'a',
            'isCorrect': true,
            'explanation': 'Correct option explanation text.',
            'timeSpentSeconds': 15,
          },
        ],
      };

      final result = ExamSubmitResultModel.fromJson(json);

      expect(result.score, equals(18));
      expect(result.total, equals(20));
      expect(result.percentage, equals(90.0));
      expect(result.details.length, equals(1));
      expect(result.details.first.isCorrect, isTrue);
    });

    testWidgets('2. Tapping Submit Exam opens confirmation dialog with counts',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_99',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question Stem Text',
            options: [QuestionOptionModel(id: 'a', text: 'Option A')],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Exam',
          session: session,
        ),
      ));

      await tester.tap(find.text('Submit Exam'));
      await tester.pumpAndSettle();

      expect(find.text('Submit Exam?'), findsOneWidget);
      expect(find.text('Answered Questions:'), findsOneWidget);
      expect(find.text('Unanswered Questions:'), findsOneWidget);
      expect(find.text('Confirm Submit'), findsOneWidget);
    });

    testWidgets(
        '3. Confirming submit calls submitExam datasource with exact DTO payload',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_99',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question Stem Text',
            options: [QuestionOptionModel(id: 'a', text: 'Option A')],
          ),
        ],
      );
      final fakeDataSource = FakeSubmitExamsRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Exam',
          session: session,
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      // Select option
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // Open submit dialog
      await tester.tap(find.text('Submit Exam'));
      await tester.pumpAndSettle();

      // Confirm submit
      await tester.tap(find.text('Confirm Submit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDataSource.submitExamCallCount, equals(1));
      expect(fakeDataSource.lastAttemptId, equals('att_99'));
      expect(fakeDataSource.lastDto?.answers.length, equals(1));
      expect(
          fakeDataSource.lastDto?.answers.first.selectedOptionId, equals('a'));
    });

    testWidgets('4. Submit API failure surfaces user-friendly error SnackBar',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_99',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question Stem Text',
            options: [QuestionOptionModel(id: 'a', text: 'Option A')],
          ),
        ],
      );
      final fakeDataSource = FakeSubmitExamsRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Exam time has expired',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Exam',
          session: session,
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.tap(find.text('Submit Exam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Submit'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Exam time has expired'), findsOneWidget);
    });

    testWidgets(
        '5. Day 49: ExamSubmitResultPage displays score, percentage, and neutral completion header',
        (WidgetTester tester) async {
      const result = ExamSubmitResultModel(
        score: 42,
        total: 50,
        percentage: 84.0,
        details: [],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        const ExamSubmitResultPage(
          examTitle: 'Pharmacology Mock Exam',
          result: result,
        ),
      ));

      expect(find.text('Pharmacology Mock Exam'), findsOneWidget);
      expect(find.text('Exam Submitted Successfully'), findsOneWidget);
      expect(find.text('42 / 50'), findsOneWidget);
      expect(find.text('84.0%'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });
}
