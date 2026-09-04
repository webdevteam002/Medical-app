import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:medstudy/features/exams/data/models/exam_attempt_history_model.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_history_page.dart';

class FakeHistoryExamsRemoteDataSource extends ExamsRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int getExamAttemptsCallCount = 0;

  FakeHistoryExamsRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<ExamAttemptHistoryModel>> getExamAttempts() async {
    getExamAttemptsCallCount++;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load exam attempt history.');
    }

    if (isEmpty) {
      return [];
    }

    return [
      ExamAttemptHistoryModel(
        id: 'att_101',
        examTitle: 'Anatomy Mock Exam 1',
        subjectName: 'Anatomy',
        score: 45,
        total: 50,
        percentage: 90.0,
        startedAt: DateTime.parse('2026-09-03T09:00:00.000Z'),
        completedAt: DateTime.parse('2026-09-03T09:45:00.000Z'),
      ),
    ];
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 52 Exam Attempt History Unit & Widget Tests', () {
    test(
        '1. ExamAttemptHistoryModel parses exact NestJS response JSON correctly',
        () {
      final json = {
        'id': 'att_123',
        'examTitle': 'Physiology Board Mock 2026',
        'subjectName': 'Physiology',
        'score': 38,
        'total': 40,
        'percentage': 95.0,
        'startedAt': '2026-09-03T08:00:00.000Z',
        'completedAt': '2026-09-03T08:40:00.000Z',
      };

      final item = ExamAttemptHistoryModel.fromJson(json);

      expect(item.id, equals('att_123'));
      expect(item.examTitle, equals('Physiology Board Mock 2026'));
      expect(item.subjectName, equals('Physiology'));
      expect(item.score, equals(38));
      expect(item.total, equals(40));
      expect(item.percentage, equals(95.0));
    });

    testWidgets('2. ExamHistoryPage renders attempt history cards',
        (WidgetTester tester) async {
      final fakeDataSource = FakeHistoryExamsRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        ExamHistoryPage(
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getExamAttemptsCallCount, equals(1));
      expect(find.text('Past Exam Attempts'), findsOneWidget);
      expect(find.text('Anatomy Mock Exam 1'), findsOneWidget);
      expect(find.text('Anatomy'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('45/50'), findsOneWidget);
    });

    testWidgets('3. Empty response renders clean empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeHistoryExamsRemoteDataSource(isEmpty: true);

      await tester.pumpWidget(createWidgetUnderTest(
        ExamHistoryPage(
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No past exam attempts found'), findsOneWidget);
    });

    testWidgets('4. API failure renders error message & Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeHistoryExamsRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Network timeout loading history',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamHistoryPage(
          examsRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Network timeout loading history'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
