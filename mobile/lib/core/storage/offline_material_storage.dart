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
      if (content.isEmpty) return [];

      final List jsonList = jsonDecode(content) as List;
      return jsonList
          .map((item) =>
              OfflineMaterialModel.fromJson(item as Map<String, dynamic>))
          .toList();
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
    final filePath = path.join(dir.path, '${model.materialId}.enc');

    final encryptedBytes = await _encryptionService.encryptBytes(rawBytes);
    final file = File(filePath);
    await file.writeAsBytes(encryptedBytes, flush: true);

    final updatedModel = OfflineMaterialModel(
      materialId: model.materialId,
      title: model.title,
      type: model.type,
      topicId: model.topicId,
      fileSizeBytes: rawBytes.length.toString(),
      downloadedAt: model.downloadedAt,
      localPath: filePath,
      isEncrypted: true,
    );

    final currentList = await listMaterials();
    currentList.removeWhere((item) => item.materialId == model.materialId);
    currentList.add(updatedModel);

    await _saveIndex(currentList);
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
    final currentList = await listMaterials();
    final target = currentList.firstWhere(
      (item) => item.materialId == materialId,
      orElse: () => OfflineMaterialModel(
        materialId: '',
        title: '',
        type: '',
        fileSizeBytes: '0',
        downloadedAt: DateTime.now(),
        localPath: '',
      ),
    );

    if (target.materialId.isNotEmpty && target.localPath.isNotEmpty) {
      final file = File(target.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

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
