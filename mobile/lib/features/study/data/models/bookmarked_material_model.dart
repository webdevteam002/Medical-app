class BookmarkedMaterialModel {
  final String id;
  final String title;
  final String type;
  final String? subjectId;
  final bool isPastPaper;
  final String fileSizeBytes;
  final DateTime? bookmarkedAt;

  const BookmarkedMaterialModel({
    required this.id,
    required this.title,
    required this.type,
    this.subjectId,
    this.isPastPaper = false,
    required this.fileSizeBytes,
    this.bookmarkedAt,
  });

  factory BookmarkedMaterialModel.fromJson(Map<String, dynamic> json) {
    return BookmarkedMaterialModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Bookmarked Material',
      type: json['type'] as String? ?? 'PDF',
      subjectId: json['subjectId'] as String?,
      isPastPaper: json['isPastPaper'] as bool? ?? false,
      fileSizeBytes: json['fileSizeBytes']?.toString() ?? '0',
      bookmarkedAt: json['bookmarkedAt'] != null
          ? DateTime.tryParse(json['bookmarkedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'subjectId': subjectId,
      'isPastPaper': isPastPaper,
      'fileSizeBytes': fileSizeBytes,
      'bookmarkedAt': bookmarkedAt?.toIso8601String(),
    };
  }
}
