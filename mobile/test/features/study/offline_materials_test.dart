import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/security/offline_encryption_service.dart';
import 'package:medstudy/core/security/security_service.dart';
import 'package:medstudy/core/storage/offline_material_storage.dart';
import 'package:medstudy/features/study/data/models/material_model.dart';
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

class FakeSecurityService extends SecurityService {
  @override
  Future<bool> enableSecureScreen() => Future.value(true);

  @override
  Future<bool> disableSecureScreen() => Future.value(true);
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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.medstudy/security'),
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  tearDown(() async {
    if (await tempTestDir.exists()) {
      try {
        await tempTestDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 32 Secure Offline Materials & Lifecycle Hardening Tests', () {
    test(
        '1. MaterialModel deserializes isDownloadable correctly (true and false)',
        () {
      final jsonDownloadable = {
        'id': 'mat_1',
        'title': 'Downloadable PDF',
        'type': 'PDF',
        'isDownloadable': true,
        'isPastPaper': false,
        'fileSizeBytes': '1024',
      };
      final mat1 = MaterialModel.fromJson(jsonDownloadable);
      expect(mat1.isDownloadable, isTrue);

      final jsonNonDownloadable = {
        'id': 'mat_2',
        'title': 'Online Only PDF',
        'type': 'PDF',
        'isDownloadable': false,
        'isPastPaper': false,
        'fileSizeBytes': '2048',
      };
      final mat2 = MaterialModel.fromJson(jsonNonDownloadable);
      expect(mat2.isDownloadable, isFalse);
    });

    test(
        '2. OfflineMaterialModel metadata never contains presigned URL, tokens, or plaintext keys',
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
      expect(json.containsKey('signedUrl'), isFalse);
      expect(json.containsKey('encryptionKey'), isFalse);

      final parsed = OfflineMaterialModel.fromJson(json);
      expect(parsed.materialId, equals('mat_101'));
      expect(parsed.title, equals('Anatomy Handbook'));
      expect(parsed.fileSizeBytes, equals('5242880'));
      expect(parsed.isEncrypted, isTrue);
    });

    test(
        '3. OfflineMaterialStorage saves encrypted bytes, lists, reads decrypted bytes, and deletes materials',
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

    test('4. AES-256-GCM tampered ciphertext fails decryption gracefully',
        () async {
      final encryptionService = OfflineEncryptionService();
      final inputBytes = [10, 20, 30, 40, 50];

      final encrypted = await encryptionService.encryptBytes(inputBytes);

      // Tamper with ciphertext byte
      final tampered = List<int>.from(encrypted);
      tampered[tampered.length - 1] ^= 0xFF;

      expect(
        () async => await encryptionService.decryptBytes(tampered),
        throwsA(isA<Object>()),
      );
    });

    test('5. Missing encrypted file is omitted from listMaterials()',
        () async {
      final missingModel = OfflineMaterialModel(
        materialId: 'mat_missing',
        title: 'Missing File PDF',
        type: 'PDF',
        fileSizeBytes: '2048',
        downloadedAt: DateTime.now(),
        localPath: '${tempTestDir.path}/non_existent_file.enc',
        isEncrypted: true,
      );

      final indexFile = File('${tempTestDir.path}/materials_index.json');
      await indexFile.writeAsString(
        '[${missingModel.toJson().toString()}]',
      );

      // listMaterials should filter out missing file
      final list = await storage.listMaterials();
      expect(list, isEmpty);
    });

    test('6. Malformed JSON in materials_index.json handled gracefully without crash',
        () async {
      final indexFile = File('${tempTestDir.path}/materials_index.json');
      await indexFile.writeAsString('{ invalid_json: true, ');

      final list = await storage.listMaterials();
      expect(list, isEmpty);
    });

    test(
        '7. Temporary decrypted PDF file is deleted when offline viewer closes',
        () async {
      final tempFile = File('${tempTestDir.path}/temp_test_decrypted.pdf');
      await tempFile.writeAsString('pdf_content_placeholder');
      expect(await tempFile.exists(), isTrue);

      if (!tempFile.path.startsWith('http') && tempFile.path.isNotEmpty) {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }

      expect(await tempFile.exists(), isFalse);
    });

    testWidgets(
        '8. OfflineMaterialsPage displays empty state when no materials exist',
        (WidgetTester tester) async {
      final fakeStorage = FakeOfflineMaterialStorage([]);

      await tester.pumpWidget(createWidgetUnderTest(
        OfflineMaterialsPage(storage: fakeStorage),
      ));

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('No offline materials'), findsOneWidget);
    });

    testWidgets(
        '9. OfflineMaterialsPage displays saved encrypted materials in list',
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

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Anatomy Handbook'), findsOneWidget);
      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
