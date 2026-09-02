import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/home/presentation/widgets/study_destination_view.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/year_model.dart';

class FakeStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int fetchCount = 0;

  FakeStudyRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<YearModel>> getYears() async {
    fetchCount++;
    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Failed to load study years');
    }
    if (isEmpty) {
      return [];
    }
    return const [
      YearModel(
        id: '1',
        name: 'First Year MBBS',
        slug: '1st-year',
        sortOrder: 1,
      ),
      YearModel(
        id: '2',
        name: 'Second Year MBBS',
        slug: '2nd-year',
        sortOrder: 2,
      ),
    ];
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Day 13 Years List Unit & Widget Tests', () {
    test('1. YearModel parses JSON contract correctly', () {
      final json = {
        'id': 'clx123',
        'name': 'First Year MBBS',
        'slug': '1st-year',
        'sortOrder': 1,
      };

      final year = YearModel.fromJson(json);

      expect(year.id, equals('clx123'));
      expect(year.name, equals('First Year MBBS'));
      expect(year.slug, equals('1st-year'));
      expect(year.sortOrder, equals(1));
    });

    testWidgets('2. Successful GET /years displays years list',
        (WidgetTester tester) async {
      final fakeDataSource = FakeStudyRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        StudyDestinationView(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.fetchCount, equals(1));
      expect(find.text('First Year MBBS'), findsOneWidget);
      expect(find.text('Second Year MBBS'), findsOneWidget);
      expect(find.text('Slug: 1st-year'), findsOneWidget);
    });

    testWidgets('3. Empty response displays empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeStudyRemoteDataSource(isEmpty: true);

      await tester.pumpWidget(createWidgetUnderTest(
        StudyDestinationView(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No study years available'), findsOneWidget);
    });

    testWidgets('4. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeStudyRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Unable to connect to server',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        StudyDestinationView(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unable to connect to server'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeDataSource.fetchCount, equals(2));
    });
  });
}
