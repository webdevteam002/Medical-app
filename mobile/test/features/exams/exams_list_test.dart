import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:medstudy/features/exams/data/models/exam_model.dart';
import 'package:medstudy/features/home/presentation/widgets/exams_destination_view.dart';

class FakeExamsRemoteDataSource extends ExamsRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int getExamsCallCount = 0;
  String? lastYearSlug;
  String? lastSubjectId;

  FakeExamsRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<ExamModel>> getExams({
    String? yearSlug,
    String? subjectId,
  }) async {
    getExamsCallCount++;
    lastYearSlug = yearSlug;
    lastSubjectId = subjectId;

    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Failed to load published exams.');
    }
    if (isEmpty) {
      return [];
    }
    return [
      const ExamModel(
        id: 'exam_1',
        title: 'Anatomy Midterm Mock Exam 2026',
        durationMinutes: 60,
        questionCount: 50,
        subjectName: 'Anatomy',
        subjectSlug: 'anatomy',
        yearName: 'Year 1',
        yearSlug: 'year-1',
      ),
      const ExamModel(
        id: 'exam_2',
        title: 'Physiology Comprehensive Test',
        durationMinutes: 45,
        questionCount: 40,
        subjectName: 'Physiology',
        subjectSlug: 'physiology',
        yearName: 'Year 1',
        yearSlug: 'year-1',
      ),
    ];
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('Day 41 Exams List Unit & Widget Tests', () {
    test('1. ExamModel parses exact NestJS JSON contract correctly', () {
      final json = {
        'id': 'exam_101',
        'title': 'Pathology Block Exam',
        'durationMinutes': 90,
        'questionCount': 75,
        'subject': {
          'name': 'Pathology',
          'slug': 'pathology',
          'year': {
            'name': 'Year 2',
            'slug': 'year-2',
          },
        },
      };

      final model = ExamModel.fromJson(json);

      expect(model.id, equals('exam_101'));
      expect(model.title, equals('Pathology Block Exam'));
      expect(model.durationMinutes, equals(90));
      expect(model.questionCount, equals(75));
      expect(model.subjectName, equals('Pathology'));
      expect(model.subjectSlug, equals('pathology'));
      expect(model.yearName, equals('Year 2'));
      expect(model.yearSlug, equals('year-2'));
    });

    testWidgets(
        '2. ExamsDestinationView fetches and renders published exams list',
        (WidgetTester tester) async {
      final fakeDataSource = FakeExamsRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        ExamsDestinationView(examsRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDataSource.getExamsCallCount, equals(1));
      expect(find.text('Anatomy Midterm Mock Exam 2026'), findsOneWidget);
      expect(find.text('Physiology Comprehensive Test'), findsOneWidget);
      expect(find.text('60 mins'), findsOneWidget);
      expect(find.text('50 questions'), findsOneWidget);
    });

    testWidgets('3. Empty response displays empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeExamsRemoteDataSource(isEmpty: true);

      await tester.pumpWidget(createWidgetUnderTest(
        ExamsDestinationView(examsRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No exams published yet'), findsOneWidget);
    });

    testWidgets('4. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeExamsRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Network timeout loading exams',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamsDestinationView(examsRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Network timeout loading exams'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeDataSource.getExamsCallCount, equals(2));
    });
  });
}
