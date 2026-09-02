class TopicModel {
  final String id;
  final String subjectId;
  final String name;
  final int sortOrder;

  const TopicModel({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.sortOrder,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      name: json['name'] as String? ?? 'Medical Topic',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'sortOrder': sortOrder,
    };
  }
}
