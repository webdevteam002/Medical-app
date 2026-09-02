import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/topic_model.dart';
import 'package:medstudy/features/study/presentation/pages/topics_page.dart';

class FakeTopicsStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int getTopicsCallCount = 0;
  String? lastSubjectId;

  FakeTopicsStudyRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<TopicModel>> getTopics(String subjectId) async {
    getTopicsCallCount++;
    lastSubjectId = subjectId;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load topics for this subject');
    }
    if (isEmpty) {
      return [];
    }
    return const [
      TopicModel(
        id: 'top1',
        subjectId: 'sub1',
        name: 'Upper Limb & Brachial Plexus',
        sortOrder: 1,
      ),
      TopicModel(
        id: 'top2',
        subjectId: 'sub1',
        name: 'Lower Limb & Femoral Triangle',
        sortOrder: 2,
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

  group('Day 15 Topics List Unit & Widget Tests', () {
    test('1. TopicModel parses JSON contract correctly', () {
      final json = {
        'id': 'clxtopic123',
        'subjectId': 'clxsubject123',
        'name': 'Upper Limb & Brachial Plexus',
        'sortOrder': 1,
      };

      final topic = TopicModel.fromJson(json);

      expect(topic.id, equals('clxtopic123'));
      expect(topic.subjectId, equals('clxsubject123'));
      expect(topic.name, equals('Upper Limb & Brachial Plexus'));
      expect(topic.sortOrder, equals(1));
    });

    testWidgets(
        '2. TopicsPage fetches and displays topics list for selected subject',
        (WidgetTester tester) async {
      final fakeDataSource = FakeTopicsStudyRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        TopicsPage(
          subjectId: 'sub1',
          subjectName: 'Anatomy',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getTopicsCallCount, equals(1));
      expect(fakeDataSource.lastSubjectId, equals('sub1'));
      expect(find.text('Anatomy Topics'), findsOneWidget);
      expect(find.text('Upper Limb & Brachial Plexus'), findsOneWidget);
      expect(find.text('Lower Limb & Femoral Triangle'), findsOneWidget);
    });

    testWidgets('3. Empty topics response displays empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeTopicsStudyRemoteDataSource(isEmpty: true);

      await tester.pumpWidget(createWidgetUnderTest(
        TopicsPage(
          subjectId: 'sub1',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No topics available for this subject'), findsOneWidget);
    });

    testWidgets('4. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeTopicsStudyRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Network timeout loading topics',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        TopicsPage(
          subjectId: 'sub1',
          studyRemoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Network timeout loading topics'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeDataSource.getTopicsCallCount, equals(2));
    });
  });
}
