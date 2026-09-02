class YearModel {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  const YearModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
  });

  factory YearModel.fromJson(Map<String, dynamic> json) {
    return YearModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Medical Year',
      slug: json['slug'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'sortOrder': sortOrder,
    };
  }
}
