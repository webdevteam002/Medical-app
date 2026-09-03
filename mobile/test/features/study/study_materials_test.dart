import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/core/storage/offline_material_storage.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/bookmarked_material_model.dart';
import 'package:medstudy/features/study/data/models/material_model.dart';
import 'package:medstudy/features/study/data/models/offline_material_model.dart';
import 'package:medstudy/features/study/presentation/pages/materials_page.dart';

class FakeMaterialsStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFail;
  final bool isEmpty;
  final String? errorMessage;
  int getMaterialsCallCount = 0;
  String? lastSubjectId;
  String? lastTopicId;

  FakeMaterialsStudyRemoteDataSource({
    this.shouldFail = false,
    this.isEmpty = false,
    this.errorMessage,
  });

  @override
  Future<List<BookmarkedMaterialModel>> getBookmarks() async => [];

  @override
  Future<List<MaterialModel>> getMaterials({
    required String subjectId,
    String? topicId,
    String? searchQuery,
    bool? pastPapersOnly,
  }) async {
    getMaterialsCallCount++;
    lastSubjectId = subjectId;
    lastTopicId = topicId;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load materials for this topic');
    }
    if (isEmpty) {
      return [];
    }
    return [
      MaterialModel(
        id: 'mat1',
        title: 'Brachial Plexus Notes & Diagrams',
        type: 'PDF',
        isDownloadable: true,
        isPastPaper: false,
        fileSizeBytes: '2458104',
        topicId: topicId ?? 'top1',
        createdAt: DateTime.parse('2026-09-02T10:00:00.000Z'),
      ),
      MaterialModel(
        id: 'mat2',
        title: 'Upper Limb Anatomy Lecture Video',
        type: 'VIDEO',
        isDownloadable: false,
        isPastPaper: false,
        fileSizeBytes: '104857600',
        topicId: topicId ?? 'top1',
        createdAt: DateTime.parse('2026-09-02T11:00:00.000Z'),
      ),
    ];
  }
}

class FakeMaterialsOfflineStorage extends OfflineMaterialStorage {
  @override
  Future<List<OfflineMaterialModel>> listMaterials() async => [];
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 16 Materials List Unit & Widget Tests', () {
    test('1. MaterialModel parses exact JSON contract correctly', () {
      final json = {
        'id': 'clxmat123',
        'title': 'Brachial Plexus Notes & Diagrams',
        'type': 'PDF',
        'isDownloadable': true,
        'isPastPaper': true,
        'pastPaperYear': 2024,
        'pastPaperSession': 'Annual',
        'fileSizeBytes': '2458104',
        'topicId': 'clxtopic123',
        'createdAt': '2026-09-02T10:00:00.000Z',
      };

      final material = MaterialModel.fromJson(json);

      expect(material.id, equals('clxmat123'));
      expect(material.title, equals('Brachial Plexus Notes & Diagrams'));
      expect(material.type, equals('PDF'));
      expect(material.isDownloadable, isTrue);
      expect(material.isPastPaper, isTrue);
      expect(material.pastPaperYear, equals(2024));
      expect(material.pastPaperSession, equals('Annual'));
      expect(material.fileSizeBytes, equals('2458104'));
      expect(material.topicId, equals('clxtopic123'));
      expect(material.createdAt, isNotNull);
    });

    testWidgets(
        '2. MaterialsPage fetches and displays materials list for selected topic',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialsStudyRemoteDataSource();
      final fakeStorage = FakeMaterialsOfflineStorage();

      await tester.pumpWidget(createWidgetUnderTest(
        MaterialsPage(
          subjectId: 'sub1',
          topicId: 'top1',
          topicName: 'Upper Limb',
          studyRemoteDataSource: fakeDataSource,
          offlineMaterialStorage: fakeStorage,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getMaterialsCallCount, equals(1));
      expect(fakeDataSource.lastSubjectId, equals('sub1'));
      expect(fakeDataSource.lastTopicId, equals('top1'));
      expect(find.text('Upper Limb Materials'), findsOneWidget);
      expect(find.text('Brachial Plexus Notes & Diagrams'), findsOneWidget);
      expect(find.text('Upper Limb Anatomy Lecture Video'), findsOneWidget);
      expect(find.text('2.3 MB'), findsOneWidget);
    });

    testWidgets('3. Empty materials response displays empty state message',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialsStudyRemoteDataSource(isEmpty: true);
      final fakeStorage = FakeMaterialsOfflineStorage();

      await tester.pumpWidget(createWidgetUnderTest(
        MaterialsPage(
          subjectId: 'sub1',
          topicId: 'top1',
          studyRemoteDataSource: fakeDataSource,
          offlineMaterialStorage: fakeStorage,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
          find.text('No materials available for this topic'), findsOneWidget);
    });

    testWidgets('4. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialsStudyRemoteDataSource(
        shouldFail: true,
        errorMessage: 'Network error loading materials',
      );
      final fakeStorage = FakeMaterialsOfflineStorage();

      await tester.pumpWidget(createWidgetUnderTest(
        MaterialsPage(
          subjectId: 'sub1',
          topicId: 'top1',
          studyRemoteDataSource: fakeDataSource,
          offlineMaterialStorage: fakeStorage,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Network error loading materials'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeDataSource.getMaterialsCallCount, equals(2));
    });

    testWidgets(
        '5. MaterialsPage search input updates query and triggers search fetch',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialsStudyRemoteDataSource();
      final fakeStorage = FakeMaterialsOfflineStorage();

      await tester.pumpWidget(createWidgetUnderTest(
        MaterialsPage(
          subjectId: 'sub1',
          topicId: 'top1',
          studyRemoteDataSource: fakeDataSource,
          offlineMaterialStorage: fakeStorage,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Brachial');
      await tester.pump(const Duration(milliseconds: 350));

      expect(fakeDataSource.getMaterialsCallCount, greaterThan(1));
    });

    testWidgets(
        '6. Day 38/39 Hardening: Clearing search input resets query and refetches materials',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialsStudyRemoteDataSource();
      final fakeStorage = FakeMaterialsOfflineStorage();

      await tester.pumpWidget(createWidgetUnderTest(
        MaterialsPage(
          subjectId: 'sub1',
          topicId: 'top1',
          studyRemoteDataSource: fakeDataSource,
          offlineMaterialStorage: fakeStorage,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Brachial');
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Brachial Plexus Notes & Diagrams'), findsOneWidget);
    });
  });
}
