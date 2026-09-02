class MaterialModel {
  final String id;
  final String title;
  final String type;
  final bool isDownloadable;
  final bool isPastPaper;
  final int? pastPaperYear;
  final String? pastPaperSession;
  final String fileSizeBytes;
  final String? topicId;
  final DateTime? createdAt;

  const MaterialModel({
    required this.id,
    required this.title,
    required this.type,
    required this.isDownloadable,
    required this.isPastPaper,
    this.pastPaperYear,
    this.pastPaperSession,
    required this.fileSizeBytes,
    this.topicId,
    this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Study Material',
      type: json['type'] as String? ?? 'PDF',
      isDownloadable: json['isDownloadable'] as bool? ?? true,
      isPastPaper: json['isPastPaper'] as bool? ?? false,
      pastPaperYear: (json['pastPaperYear'] as num?)?.toInt(),
      pastPaperSession: json['pastPaperSession'] as String?,
      fileSizeBytes: json['fileSizeBytes']?.toString() ?? '0',
      topicId: json['topicId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'isDownloadable': isDownloadable,
      'isPastPaper': isPastPaper,
      'pastPaperYear': pastPaperYear,
      'pastPaperSession': pastPaperSession,
      'fileSizeBytes': fileSizeBytes,
      'topicId': topicId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
