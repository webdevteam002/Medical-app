import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../security/offline_encryption_service.dart';
import '../../features/study/data/models/offline_material_model.dart';

class OfflineMaterialStorage {
  final Directory? overrideDirectory;
  final OfflineEncryptionService _encryptionService;

  OfflineMaterialStorage({
    this.overrideDirectory,
    OfflineEncryptionService? encryptionService,
  }) : _encryptionService = encryptionService ?? OfflineEncryptionService();

  Future<Directory> _getStorageDir() async {
    if (overrideDirectory != null) {
      if (!await overrideDirectory!.exists()) {
        await overrideDirectory!.create(recursive: true);
      }
      return overrideDirectory!;
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineDir =
          Directory(path.join(appDocDir.path, 'medstudy_offline'));
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      return offlineDir;
    } catch (_) {
      final tempDir =
          await Directory.systemTemp.createTemp('medstudy_offline_');
      return tempDir;
    }
  }

  Future<File> _getIndexFile() async {
    final dir = await _getStorageDir();
    return File(path.join(dir.path, 'materials_index.json'));
  }

  Future<List<OfflineMaterialModel>> listMaterials() async {
    try {
      final indexFile = await _getIndexFile();
      if (!await indexFile.exists()) {
        return [];
      }

      final content = await indexFile.readAsString();
      if (content.trim().isEmpty) return [];

      dynamic jsonObject;
      try {
        jsonObject = jsonDecode(content);
      } catch (_) {
        // Malformed JSON protection: return empty list without crashing
        return [];
      }

      if (jsonObject is! List) return [];

      final validItems = <OfflineMaterialModel>[];
      for (final item in jsonObject) {
        if (item is Map<String, dynamic>) {
          try {
            final model = OfflineMaterialModel.fromJson(item);
            if (model.materialId.trim().isNotEmpty) {
              if (model.localPath.isEmpty || await File(model.localPath).exists()) {
                validItems.add(model);
              }
            }
          } catch (_) {
            // Ignore malformed individual items
          }
        }
      }
      return validItems;
    } catch (_) {
      return [];
    }
  }

  Future<bool> exists(String materialId) async {
    final list = await listMaterials();
    return list.any((item) => item.materialId == materialId);
  }

  Future<void> saveMaterial({
    required OfflineMaterialModel model,
    required List<int> rawBytes,
  }) async {
    final dir = await _getStorageDir();
    final tempPath = path.join(dir.path, '${model.materialId}.tmp_enc');
    final finalPath = path.join(dir.path, '${model.materialId}.enc');

    final tempFile = File(tempPath);
    final finalFile = File(finalPath);

    try {
      final encryptedBytes = await _encryptionService.encryptBytes(rawBytes);
      await tempFile.writeAsBytes(encryptedBytes, flush: true);

      // Atomic rename/move to final file path after complete write
      if (await tempFile.exists()) {
        await tempFile.rename(finalPath);
      }

      final updatedModel = OfflineMaterialModel(
        materialId: model.materialId,
        title: model.title,
        type: model.type,
        topicId: model.topicId,
        fileSizeBytes: rawBytes.length.toString(),
        downloadedAt: model.downloadedAt,
        localPath: finalPath,
        isEncrypted: true,
      );

      final currentList = await listMaterials();
      currentList.removeWhere((item) => item.materialId == model.materialId);
      currentList.add(updatedModel);

      await _saveIndex(currentList);
    } catch (e) {
      // Clean up temporary file if download or encryption was interrupted
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (await finalFile.exists() && !(await exists(model.materialId))) {
        try {
          await finalFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<List<int>> readDecryptedBytes(String materialId) async {
    final localPath = await getLocalPath(materialId);
    if (localPath == null || localPath.isEmpty) {
      throw Exception('Material not found in offline storage index.');
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Encrypted offline file missing from storage.');
    }

    final encryptedBytes = await file.readAsBytes();
    return await _encryptionService.decryptBytes(encryptedBytes);
  }

  Future<void> deleteMaterial(String materialId) async {
    final dir = await _getStorageDir();
    final finalFile = File(path.join(dir.path, '$materialId.enc'));
    final tempFile = File(path.join(dir.path, '$materialId.tmp_enc'));

    try {
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}

    final currentList = await listMaterials();
    currentList.removeWhere((item) => item.materialId == materialId);
    await _saveIndex(currentList);
  }

  Future<void> clearAll() async {
    final dir = await _getStorageDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  Future<String?> getLocalPath(String materialId) async {
    final list = await listMaterials();
    for (final item in list) {
      if (item.materialId == materialId) {
        return item.localPath;
      }
    }
    return null;
  }

  Future<void> _saveIndex(List<OfflineMaterialModel> list) async {
    final indexFile = await _getIndexFile();
    final jsonList = list.map((item) => item.toJson()).toList();
    await indexFile.writeAsString(jsonEncode(jsonList), flush: true);
  }
}
