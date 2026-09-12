/// Shared AI-6 citation model — server-authored RAG metadata only.
class AiCitation {
  final String materialId;
  final String title;
  final String? subjectName;
  final String? topicName;
  final String? yearSlug;
  final int? pageStart;
  final int? pageEnd;
  final String chunkId;
  final String documentId;
  final String? contentHash;
  final int? chunkIndex;
  final String sourceType;
  final double? similarity;

  const AiCitation({
    required this.materialId,
    required this.title,
    this.subjectName,
    this.topicName,
    this.yearSlug,
    this.pageStart,
    this.pageEnd,
    required this.chunkId,
    this.documentId = '',
    this.contentHash,
    this.chunkIndex,
    this.sourceType = 'rag',
    this.similarity,
  });

  factory AiCitation.fromJson(Map<String, dynamic> json) {
    return AiCitation(
      materialId: json['materialId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String?,
      topicName: json['topicName'] as String?,
      yearSlug: json['yearSlug'] as String?,
      pageStart: json['pageStart'] as int?,
      pageEnd: json['pageEnd'] as int?,
      chunkId: json['chunkId'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      contentHash: json['contentHash'] as String?,
      chunkIndex: json['chunkIndex'] as int?,
      sourceType: json['sourceType'] as String? ?? 'rag',
      similarity: _asDouble(json['similarity']),
    );
  }

  /// Page label only when server provided page metadata — never invent.
  String? get pageLabel {
    if (pageStart == null) return null;
    if (pageEnd != null && pageEnd != pageStart) {
      return 'Pages $pageStart–$pageEnd';
    }
    return 'Page $pageStart';
  }

  String get contextLabel {
    final parts = <String>[
      if (subjectName != null && subjectName!.isNotEmpty) subjectName!,
      if (topicName != null && topicName!.isNotEmpty) topicName!,
      if (yearSlug != null && yearSlug!.isNotEmpty) yearSlug!,
    ];
    return parts.join(' · ');
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

typedef ExplainMcqCitation = AiCitation;
typedef AiChatCitation = AiCitation;
