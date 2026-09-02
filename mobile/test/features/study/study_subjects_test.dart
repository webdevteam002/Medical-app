import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/subject_model.dart';
import 'package:medstudy/features/study/presentation/pages/subjects_page.dart';

class FakeSubjectsStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int getSubjectsCallCount = 0;
  String? lastYearSlug;

  FakeSubjectsStudyRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<SubjectModel>> getSubjects(String yearSlug) async {
    getSubjectsCallCount++;
    lastYearSlug = yearSlug;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load subjects for this year');
    }
    if (isEmpty) {
      return [];
    }
    return const [
      SubjectModel(
        id: 'sub1',
        name: 'Anatomy',
        slug: 'anatomy',
        sortOrder: 1,
        yearId: 'year1',
      ),
      SubjectModel(
        id: 'sub2',
        name: 'Physiology',
        slug: 'physiology',
        sortOrder: 2,
        yearId: 'year1',
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

  group('Day 14 Subjects List Unit & Widget Tests', () {
    test('1. SubjectModel parses JSON contract correctly', () {
      final json = {
        'id': 'clxsub123',
        'name': 'Anatomy',
        'slug': 'anatomy',
        'sortOrder': 1,
        'yearId': 'clxyear123',
      };

      final subject = SubjectModel.fromJson(json);

      expect(subject.id, equals('clxsub123'));
      expect(subject.name, equals('Anatomy'));
      expect(subject.slug, equals('anatomy'));
      expect(subject.sortOrder, equals(1));
      expect(subject.yearId, equals('clxyear123'));
    });

    testWidgets(
        '2. SubjectsPage fetches and displays subjects list for selected year',
        (WidgetTester tester) async {
      final fakeDataSource = FakeSubjectsStudyRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        SubjectsPage(
          yearSlug: '1st-year',
          yearName: 'First Year MBBS',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getSubjectsCallCount, equals(1));
      expect(fakeDataSource.lastYearSlug, equals('1st-year'));
      expect(find.text('First Year MBBS Subjects'), findsOneWidget);
      expect(find.text('Anatomy'), findsOneWidget);
      expect(find.text('Physiology'), findsOneWidget);
      expect(find.text('Slug: anatomy'), findsOneWidget);
    });

    testWidgets('3. Empty subjects response displays empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeSubjectsStudyRemoteDataSource(isEmpty: true);

      await tester.pumpWidget(createWidgetUnderTest(
        SubjectsPage(
          yearSlug: '1st-year',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No subjects available for this year'), findsOneWidget);
    });

    testWidgets('4. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeSubjectsStudyRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Network timeout loading subjects',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        SubjectsPage(
          yearSlug: '1st-year',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Network timeout loading subjects'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeDataSource.getSubjectsCallCount, equals(2));
    });
  });
}
