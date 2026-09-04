import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:medstudy/features/exams/data/models/exam_model.dart';
import 'package:medstudy/features/exams/data/models/exam_question_model.dart';
import 'package:medstudy/features/exams/data/models/exam_start_session_model.dart';
import 'package:medstudy/features/exams/data/models/question_option_model.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_detail_page.dart';

class FakeStartExamRemoteDataSource extends ExamsRemoteDataSource {
  final bool shouldFail;
  final String? errorMessage;
  int startExamCallCount = 0;
  String? lastExamId;

  FakeStartExamRemoteDataSource({
    this.shouldFail = false,
    this.errorMessage,
  });

  @override
  Future<ExamStartSessionModel> startExam(String examId) async {
    startExamCallCount++;
    lastExamId = examId;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'You already have an active attempt for this exam');
    }

    return ExamStartSessionModel(
      attemptId: 'att_99',
      durationMinutes: 120,
      startedAt: DateTime.parse('2026-09-03T09:00:00.000Z'),
      questions: const [
        ExamQuestionModel(
          id: 'q1',
          stem: 'Test Stem',
          options: [
            QuestionOptionModel(id: 'a', text: 'Option A'),
          ],
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

  group('Day 42-43 Exam Detail Screen Unit & Widget Tests', () {
    testWidgets(
        '1. ExamDetailPage displays title, chips, duration, and question count',
        (WidgetTester tester) async {
      const exam = ExamModel(
        id: 'exam_99',
        title: 'Gross Anatomy Final Exam',
        durationMinutes: 120,
        questionCount: 100,
        subjectName: 'Anatomy',
        yearName: 'Year 1',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        const ExamDetailPage(exam: exam),
      ));

      expect(find.text('Gross Anatomy Final Exam'), findsOneWidget);
      expect(find.text('Anatomy'), findsOneWidget);
      expect(find.text('Year 1'), findsOneWidget);
      expect(find.text('120 Minutes'), findsOneWidget);
      expect(find.text('100 Questions'), findsOneWidget);
    });

    testWidgets(
        '2. Tapping Start Exam invokes startExam datasource method and navigates',
        (WidgetTester tester) async {
      const exam = ExamModel(
        id: 'exam_99',
        title: 'Gross Anatomy Final Exam',
        durationMinutes: 120,
        questionCount: 100,
      );
      final fakeDataSource = FakeStartExamRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        ExamDetailPage(
          exam: exam,
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      expect(find.text('Exam Instructions & Rules'), findsOneWidget);
      expect(find.text('Start Exam'), findsOneWidget);

      await tester.tap(find.text('Start Exam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDataSource.startExamCallCount, equals(1));
      expect(fakeDataSource.lastExamId, equals('exam_99'));
    });

    testWidgets(
        '3. Start Exam API failure presents user-friendly error SnackBar',
        (WidgetTester tester) async {
      const exam = ExamModel(
        id: 'exam_99',
        title: 'Gross Anatomy Final Exam',
        durationMinutes: 120,
        questionCount: 100,
      );
      final fakeDataSource = FakeStartExamRemoteDataSource(
        shouldFail: true,
        errorMessage: 'You already have an active attempt for this exam',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamDetailPage(
          exam: exam,
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.tap(find.text('Start Exam'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('You already have an active attempt for this exam'),
          findsOneWidget);
    });
  });
}
