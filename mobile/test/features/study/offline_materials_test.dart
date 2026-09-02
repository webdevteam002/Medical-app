import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/security/offline_encryption_service.dart';
import 'package:medstudy/core/storage/offline_material_storage.dart';
import 'package:medstudy/features/study/data/models/offline_material_model.dart';
import 'package:medstudy/features/study/presentation/pages/offline_materials_page.dart';

class FakeOfflineMaterialStorage extends OfflineMaterialStorage {
  final List<OfflineMaterialModel> items;

  FakeOfflineMaterialStorage([List<OfflineMaterialModel>? initialItems])
      : items = initialItems ?? [];

  @override
  Future<List<OfflineMaterialModel>> listMaterials() async => items;

  @override
  Future<List<int>> readDecryptedBytes(String materialId) async {
    return [1, 2, 3, 4, 5];
  }

  @override
  Future<void> deleteMaterial(String materialId) async {
    items.removeWhere((item) => item.materialId == materialId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late OfflineMaterialStorage storage;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('medstudy_test_');
    storage = OfflineMaterialStorage(overrideDirectory: tempTestDir);

    final Map<String, String> secureValues = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          final key = methodCall.arguments['key'] as String?;
          return secureValues[key];
        }
        if (methodCall.method == 'write') {
          final key = methodCall.arguments['key'] as String?;
          final val = methodCall.arguments['value'] as String?;
          if (key != null && val != null) {
            secureValues[key] = val;
          }
          return null;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempTestDir.path;
      },
    );
  });

  tearDown(() async {
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 19/20 Offline Materials Unit & Widget Tests', () {
    test(
        '1. OfflineMaterialModel metadata never contains presigned URL, tokens, or plaintext keys',
        () {
      final now = DateTime.parse('2026-09-02T12:00:00.000Z');
      final model = OfflineMaterialModel(
        materialId: 'mat_101',
        title: 'Anatomy Handbook',
        type: 'PDF',
        topicId: 'top_1',
        fileSizeBytes: '5242880',
        downloadedAt: now,
        localPath: '/private/app/medstudy_offline/mat_101.enc',
        isEncrypted: true,
      );

      final json = model.toJson();
      expect(json['materialId'], equals('mat_101'));
      expect(json['title'], equals('Anatomy Handbook'));
      expect(json['isEncrypted'], isTrue);
      expect(json.containsKey('accessToken'), isFalse);
      expect(json.containsKey('refreshToken'), isFalse);
      expect(json.containsKey('presignedUrl'), isFalse);
      expect(json.containsKey('encryptionKey'), isFalse);

      final parsed = OfflineMaterialModel.fromJson(json);
      expect(parsed.materialId, equals('mat_101'));
      expect(parsed.title, equals('Anatomy Handbook'));
      expect(parsed.fileSizeBytes, equals('5242880'));
      expect(parsed.isEncrypted, isTrue);
    });

    test(
        '2. OfflineMaterialStorage saves encrypted bytes, lists, reads decrypted bytes, and deletes materials',
        () async {
      expect(await storage.listMaterials(), isEmpty);
      expect(await storage.exists('mat_101'), isFalse);

      final model = OfflineMaterialModel(
        materialId: 'mat_101',
        title: 'Anatomy Handbook',
        type: 'PDF',
        fileSizeBytes: '1024',
        downloadedAt: DateTime.now(),
        localPath: '',
      );

      final rawPdfBytes = [37, 80, 68, 70, 45, 49, 46, 52]; // %PDF-1.4
      await storage.saveMaterial(model: model, rawBytes: rawPdfBytes);

      expect(await storage.exists('mat_101'), isTrue);
      final list = await storage.listMaterials();
      expect(list.length, equals(1));
      expect(list.first.title, equals('Anatomy Handbook'));
      expect(list.first.isEncrypted, isTrue);

      final decryptedBytes = await storage.readDecryptedBytes('mat_101');
      expect(decryptedBytes, equals(rawPdfBytes));

      await storage.deleteMaterial('mat_101');
      expect(await storage.exists('mat_101'), isFalse);
      expect(await storage.listMaterials(), isEmpty);
    });

    test('3. OfflineEncryptionService provides encryption abstraction',
        () async {
      final encryptionService = OfflineEncryptionService();
      final inputBytes = [10, 20, 30, 40, 50];

      final encrypted = await encryptionService.encryptBytes(inputBytes);
      final decrypted = await encryptionService.decryptBytes(encrypted);

      expect(decrypted, equals(inputBytes));
    });

    testWidgets(
        '4. OfflineMaterialsPage displays empty state when no materials exist',
        (WidgetTester tester) async {
      final fakeStorage = FakeOfflineMaterialStorage([]);

      await tester.pumpWidget(createWidgetUnderTest(
        OfflineMaterialsPage(storage: fakeStorage),
      ));

      await tester.pump();

      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('No offline materials'), findsOneWidget);
    });

    testWidgets(
        '5. OfflineMaterialsPage displays saved encrypted materials in list',
        (WidgetTester tester) async {
      final model = OfflineMaterialModel(
        materialId: 'mat_101',
        title: 'Anatomy Handbook',
        type: 'PDF',
        fileSizeBytes: '5242880',
        downloadedAt: DateTime.parse('2026-09-02T10:00:00.000Z'),
        localPath: '',
        isEncrypted: true,
      );
      final fakeStorage = FakeOfflineMaterialStorage([model]);

      await tester.pumpWidget(createWidgetUnderTest(
        OfflineMaterialsPage(storage: fakeStorage),
      ));

      await tester.pump();

      expect(find.text('Anatomy Handbook'), findsOneWidget);
      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
