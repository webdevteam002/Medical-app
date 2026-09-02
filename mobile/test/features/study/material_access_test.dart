import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/core/storage/offline_material_storage.dart';
import 'package:medstudy/features/study/data/datasources/study_remote_datasource.dart';
import 'package:medstudy/features/study/data/models/material_access_model.dart';
import 'package:medstudy/features/study/data/models/material_model.dart';
import 'package:medstudy/features/study/data/models/offline_material_model.dart';
import 'package:medstudy/features/study/presentation/pages/materials_page.dart';
import 'package:medstudy/features/study/presentation/pages/pdf_viewer_page.dart';

class FakeMaterialAccessStudyRemoteDataSource extends StudyRemoteDataSource {
  final bool shouldFailMaterials;
  final bool shouldFailAccess;
  final String? errorMessage;
  int getMaterialAccessCallCount = 0;
  String? lastAccessMaterialId;

  FakeMaterialAccessStudyRemoteDataSource({
    this.shouldFailMaterials = false,
    this.shouldFailAccess = false,
    this.errorMessage,
  });

  @override
  Future<List<MaterialModel>> getMaterials({
    required String subjectId,
    String? topicId,
  }) async {
    if (shouldFailMaterials) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load materials for this topic');
    }
    return [
      MaterialModel(
        id: 'mat1',
        title: 'Brachial Plexus Notes',
        type: 'PDF',
        isDownloadable: true,
        isPastPaper: false,
        fileSizeBytes: '2458104',
        topicId: topicId ?? 'top1',
        createdAt: DateTime.parse('2026-09-02T10:00:00.000Z'),
      ),
    ];
  }

  @override
  Future<MaterialAccessModel> getMaterialAccess(String materialId) async {
    getMaterialAccessCallCount++;
    lastAccessMaterialId = materialId;

    if (shouldFailAccess) {
      throw NetworkFailure(
          errorMessage ?? 'Subscription required for this material');
    }

    return MaterialAccessModel(
      url: 'http://localhost:3000/v1/materials/$materialId/stream',
      expiresAt: DateTime.parse('2026-09-02T10:15:00.000Z'),
      watermark: 'student@medstudy.org · ID:c1a2b3c4',
    );
  }
}

class FakeTestOfflineMaterialStorage extends OfflineMaterialStorage {
  @override
  Future<List<OfflineMaterialModel>> listMaterials() async => [];
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 17/18 Material Access & Security Hardening Tests', () {
    test('1. MaterialAccessModel parses exact JSON contract correctly', () {
      final json = {
        'url': 'http://localhost:3000/v1/materials/mat123/stream',
        'expiresAt': '2026-09-02T10:15:00.000Z',
        'watermark': 'student@medstudy.org · ID:c1a2b3c4',
      };

      final access = MaterialAccessModel.fromJson(json);

      expect(access.url,
          equals('http://localhost:3000/v1/materials/mat123/stream'));
      expect(
          access.expiresAt, equals(DateTime.parse('2026-09-02T10:15:00.000Z')));
      expect(access.watermark, equals('student@medstudy.org · ID:c1a2b3c4'));
    });

    testWidgets('2. Tapping material requests access and invokes datasource',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialAccessStudyRemoteDataSource();
      final fakeStorage = FakeTestOfflineMaterialStorage();

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

      expect(find.text('Brachial Plexus Notes'), findsOneWidget);

      await tester.tap(find.text('Brachial Plexus Notes'));
      await tester.pump();

      expect(fakeDataSource.getMaterialAccessCallCount, equals(1));
      expect(fakeDataSource.lastAccessMaterialId, equals('mat1'));
    });

    testWidgets(
        '3. Failed access request displays user-friendly error snackbar',
        (WidgetTester tester) async {
      final fakeDataSource = FakeMaterialAccessStudyRemoteDataSource(
        shouldFailAccess: true,
        errorMessage: 'Active subscription required for this content',
      );
      final fakeStorage = FakeTestOfflineMaterialStorage();

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

      await tester.tap(find.text('Brachial Plexus Notes'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Active subscription required for this content'),
        findsOneWidget,
      );
    });

    testWidgets(
        '4. PdfViewerPage renders title and dynamic timestamped watermark overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const PdfViewerPage(
          title: 'Brachial Plexus Notes',
          pdfUrl: 'http://localhost:3000/v1/materials/mat1/stream',
          watermarkText: 'student@medstudy.org · ID:c1a2b3c4',
          isTestMode: true,
        ),
      ));

      expect(find.text('Brachial Plexus Notes'), findsNWidgets(2));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            (widget.data?.contains('student@medstudy.org · ID:c1a2b3c4') ??
                false)),
        findsOneWidget,
      );
    });
  });
}
