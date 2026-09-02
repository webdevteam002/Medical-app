class OfflineMaterialModel {
  final String materialId;
  final String title;
  final String type;
  final String? topicId;
  final String fileSizeBytes;
  final DateTime downloadedAt;
  final String localPath;
  final bool isEncrypted;

  OfflineMaterialModel({
    required this.materialId,
    required this.title,
    required this.type,
    this.topicId,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.localPath,
    this.isEncrypted = false,
  });

  factory OfflineMaterialModel.fromJson(Map<String, dynamic> json) {
    return OfflineMaterialModel(
      materialId: json['materialId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Material',
      type: json['type'] as String? ?? 'PDF',
      topicId: json['topicId'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as String? ?? '0',
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : DateTime.now(),
      localPath: json['localPath'] as String? ?? '',
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'title': title,
      'type': type,
      'topicId': topicId,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'localPath': localPath,
      'isEncrypted': isEncrypted,
    };
  }
}
