class SubjectModel {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final String yearId;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.yearId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Medical Subject',
      slug: json['slug'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      yearId: json['yearId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'sortOrder': sortOrder,
      'yearId': yearId,
    };
  }
}
