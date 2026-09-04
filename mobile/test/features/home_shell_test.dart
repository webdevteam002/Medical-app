import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/storage/secure_storage_service.dart';
import 'package:medstudy/features/exams/data/datasources/exams_remote_datasource.dart';
import 'package:medstudy/features/exams/data/models/exam_model.dart';
import 'package:medstudy/features/home/presentation/pages/home_page.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/year_model.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    storage.remove(key);
  }
}

class FakeStudyRemoteDataSource extends StudyRemoteDataSource {
  @override
  Future<List<YearModel>> getYears() async {
    return const [
      YearModel(
        id: '1',
        name: 'First Year MBBS',
        slug: '1st-year',
        sortOrder: 1,
      ),
    ];
  }
}

class FakeExamsRemoteDataSource extends ExamsRemoteDataSource {
  @override
  Future<List<ExamModel>> getExams(
      {String? yearSlug, String? subjectId}) async {
    return const [
      ExamModel(
        id: 'exam_1',
        title: 'Anatomy Midterm Mock Exam 2026',
        durationMinutes: 60,
        questionCount: 50,
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

  group('Day 12 Home Shell Widget Tests', () {
    testWidgets('1. Renders Home Shell with Study destination by default',
        (WidgetTester tester) async {
      final fakeStudyDs = FakeStudyRemoteDataSource();
      final fakeExamsDs = FakeExamsRemoteDataSource();
      await tester.pumpWidget(createWidgetUnderTest(
        HomePage(
          studyRemoteDataSource: fakeStudyDs,
          examsRemoteDataSource: fakeExamsDs,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('MedStudy'), findsOneWidget);
      expect(find.text('Study Library'), findsOneWidget);
      expect(find.text('First Year MBBS'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Exams'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('2. NavigationBar switches to Exams destination',
        (WidgetTester tester) async {
      final fakeStudyDs = FakeStudyRemoteDataSource();
      final fakeExamsDs = FakeExamsRemoteDataSource();
      await tester.pumpWidget(createWidgetUnderTest(
        HomePage(
          studyRemoteDataSource: fakeStudyDs,
          examsRemoteDataSource: fakeExamsDs,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exams'));
      await tester.pumpAndSettle();

      expect(find.text('QBank & Exams'), findsOneWidget);
      expect(find.text('Anatomy Midterm Mock Exam 2026'), findsOneWidget);
    });

    testWidgets('3. NavigationBar switches to Profile destination',
        (WidgetTester tester) async {
      final fakeStudyDs = FakeStudyRemoteDataSource();
      final fakeExamsDs = FakeExamsRemoteDataSource();
      await tester.pumpWidget(createWidgetUnderTest(
        HomePage(
          studyRemoteDataSource: fakeStudyDs,
          examsRemoteDataSource: fakeExamsDs,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Medical Student'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
