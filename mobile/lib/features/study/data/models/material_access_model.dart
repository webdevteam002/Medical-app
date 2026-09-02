class MaterialAccessModel {
  final String url;
  final DateTime? expiresAt;
  final String? watermark;

  const MaterialAccessModel({
    required this.url,
    this.expiresAt,
    this.watermark,
  });

  factory MaterialAccessModel.fromJson(Map<String, dynamic> json) {
    return MaterialAccessModel(
      url: json['url'] as String? ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      watermark: json['watermark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'expiresAt': expiresAt?.toIso8601String(),
      'watermark': watermark,
    };
  }
}
