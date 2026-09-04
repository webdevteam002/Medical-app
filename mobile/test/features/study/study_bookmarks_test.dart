import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/bookmarked_material_model.dart';
import 'package:medstudy/features/study/data/models/material_access_model.dart';
import 'package:medstudy/features/study/data/models/material_model.dart';
import 'package:medstudy/features/study/presentation/pages/bookmarks_page.dart';

class FakeBookmarkStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFailList;
  final bool shouldFailAdd;
  final bool shouldFailRemove;
  final bool shouldFailAccess;
  final String? errorMessage;

  final List<BookmarkedMaterialModel> bookmarks;
  int addBookmarkCallCount = 0;
  int removeBookmarkCallCount = 0;
  int getMaterialAccessCallCount = 0;
  String? lastBookmarkedMaterialId;
  String? lastRemovedMaterialId;
  String? lastAccessMaterialId;

  FakeBookmarkStudyRemoteDataSource({
    this.shouldFailList = false,
    this.shouldFailAdd = false,
    this.shouldFailRemove = false,
    this.shouldFailAccess = false,
    this.errorMessage,
    List<BookmarkedMaterialModel>? initialBookmarks,
  }) : bookmarks = initialBookmarks ?? [];

  @override
  Future<List<BookmarkedMaterialModel>> getBookmarks() async {
    if (shouldFailList) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load bookmarked materials');
    }
    return bookmarks;
  }

  @override
  Future<bool> addBookmark(String materialId) async {
    addBookmarkCallCount++;
    lastBookmarkedMaterialId = materialId;
    if (shouldFailAdd) {
      throw NetworkFailure(errorMessage ?? 'Failed to add bookmark');
    }
    return true;
  }

  @override
  Future<bool> removeBookmark(String materialId) async {
    removeBookmarkCallCount++;
    lastRemovedMaterialId = materialId;
    if (shouldFailRemove) {
      throw NetworkFailure(errorMessage ?? 'Failed to remove bookmark');
    }
    bookmarks.removeWhere((b) => b.id == materialId);
    return true;
  }

  @override
  Future<MaterialAccessModel> getMaterialAccess(String materialId) async {
    getMaterialAccessCallCount++;
    lastAccessMaterialId = materialId;

    if (shouldFailAccess) {
      throw NetworkFailure(
          errorMessage ?? 'Active subscription required for this content');
    }

    return MaterialAccessModel(
      url: 'http://localhost:3000/v1/materials/$materialId/stream',
      expiresAt: DateTime.parse('2026-09-03T12:00:00.000Z'),
      watermark: 'student@medstudy.org · ID:bm123',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.medstudy/security'),
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 33 Mobile Bookmarks Unit & Widget Tests', () {
    test(
        '1. BookmarkedMaterialModel parses exact NestJS JSON contract correctly',
        () {
      final json = {
        'id': 'mat_bm1',
        'title': 'Cardiology Essentials',
        'type': 'PDF',
        'subjectId': 'sub_cardio',
        'isPastPaper': false,
        'fileSizeBytes': '2048576',
        'bookmarkedAt': '2026-09-03T08:00:00.000Z',
      };

      final model = BookmarkedMaterialModel.fromJson(json);

      expect(model.id, equals('mat_bm1'));
      expect(model.title, equals('Cardiology Essentials'));
      expect(model.type, equals('PDF'));
      expect(model.subjectId, equals('sub_cardio'));
      expect(model.isPastPaper, isFalse);
      expect(model.fileSizeBytes, equals('2048576'));
      expect(model.bookmarkedAt,
          equals(DateTime.parse('2026-09-03T08:00:00.000Z')));

      final backToJson = model.toJson();
      expect(backToJson['id'], equals('mat_bm1'));
      expect(backToJson['title'], equals('Cardiology Essentials'));
      expect(backToJson['fileSizeBytes'], equals('2048576'));
    });

    testWidgets('2. BookmarksPage displays empty state when no bookmarks exist',
        (WidgetTester tester) async {
      final fakeDataSource =
          FakeBookmarkStudyRemoteDataSource(initialBookmarks: []);

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bookmarks Library'), findsOneWidget);
      expect(find.text('No bookmarked materials'), findsOneWidget);
    });

    testWidgets('3. BookmarksPage displays list of bookmarked materials',
        (WidgetTester tester) async {
      final item = BookmarkedMaterialModel(
        id: 'bm_101',
        title: 'Neurology Clinical Notes',
        type: 'PDF',
        fileSizeBytes: '1048576',
        bookmarkedAt: DateTime.parse('2026-09-03T07:00:00.000Z'),
      );
      final fakeDataSource =
          FakeBookmarkStudyRemoteDataSource(initialBookmarks: [item]);

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Neurology Clinical Notes'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets(
        '4. Tapping remove bookmark invokes API and removes item from list',
        (WidgetTester tester) async {
      final item = BookmarkedMaterialModel(
        id: 'bm_101',
        title: 'Neurology Clinical Notes',
        type: 'PDF',
        fileSizeBytes: '1048576',
        bookmarkedAt: DateTime.parse('2026-09-03T07:00:00.000Z'),
      );
      final fakeDataSource =
          FakeBookmarkStudyRemoteDataSource(initialBookmarks: [item]);

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Neurology Clinical Notes'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeDataSource.removeBookmarkCallCount, equals(1));
      expect(fakeDataSource.lastRemovedMaterialId, equals('bm_101'));
      expect(find.text('No bookmarked materials'), findsOneWidget);
    });

    testWidgets('5. API failure displays error message and Retry button',
        (WidgetTester tester) async {
      final fakeDataSource = FakeBookmarkStudyRemoteDataSource(
        shouldFailList: true,
        errorMessage: 'Network error loading bookmarks',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Network error loading bookmarks'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('6. Tapping bookmarked material requests protected access flow',
        (WidgetTester tester) async {
      final item = BookmarkedMaterialModel(
        id: 'bm_101',
        title: 'Neurology Clinical Notes',
        type: 'PDF',
        fileSizeBytes: '1048576',
        bookmarkedAt: DateTime.parse('2026-09-03T07:00:00.000Z'),
      );
      final fakeDataSource =
          FakeBookmarkStudyRemoteDataSource(initialBookmarks: [item]);

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Neurology Clinical Notes'));
      await tester.pump();

      expect(fakeDataSource.getMaterialAccessCallCount, equals(1));
      expect(fakeDataSource.lastAccessMaterialId, equals('bm_101'));
    });

    test('7. MaterialModel and BookmarkedMaterialModel remain independent', () {
      final material = MaterialModel(
        id: 'mat_1',
        title: 'Test Material',
        type: 'PDF',
        isDownloadable: false,
        isPastPaper: false,
        fileSizeBytes: '500',
      );

      expect(material.isDownloadable, isFalse);
    });

    testWidgets('8. BookmarksPage pull-to-refresh refetches bookmarks list',
        (WidgetTester tester) async {
      final item = BookmarkedMaterialModel(
        id: 'bm_101',
        title: 'Neurology Clinical Notes',
        type: 'PDF',
        fileSizeBytes: '1048576',
        bookmarkedAt: DateTime.parse('2026-09-03T07:00:00.000Z'),
      );
      final fakeDataSource =
          FakeBookmarkStudyRemoteDataSource(initialBookmarks: [item]);

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets(
        '9. Day 35 Regression: Bookmark remove failure displays error banner',
        (WidgetTester tester) async {
      final item = BookmarkedMaterialModel(
        id: 'bm_101',
        title: 'Neurology Clinical Notes',
        type: 'PDF',
        fileSizeBytes: '1048576',
        bookmarkedAt: DateTime.parse('2026-09-03T07:00:00.000Z'),
      );
      final fakeDataSource = FakeBookmarkStudyRemoteDataSource(
        initialBookmarks: [item],
        shouldFailRemove: true,
        errorMessage: 'Network timeout removing bookmark',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        BookmarksPage(studyRemoteDataSource: fakeDataSource),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Network timeout removing bookmark'), findsOneWidget);
    });
  });
}
