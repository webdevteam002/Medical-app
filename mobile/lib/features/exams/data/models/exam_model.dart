class ExamModel {
  final String id;
  final String title;
  final int durationMinutes;
  final int questionCount;
  final String? subjectName;
  final String? subjectSlug;
  final String? yearName;
  final String? yearSlug;

  const ExamModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.questionCount,
    this.subjectName,
    this.subjectSlug,
    this.yearName,
    this.yearSlug,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? sSlug;
    String? yName;
    String? ySlug;

    if (json['subject'] is Map<String, dynamic>) {
      final subjectMap = json['subject'] as Map<String, dynamic>;
      sName = subjectMap['name'] as String?;
      sSlug = subjectMap['slug'] as String?;
      if (subjectMap['year'] is Map<String, dynamic>) {
        final yearMap = subjectMap['year'] as Map<String, dynamic>;
        yName = yearMap['name'] as String?;
        ySlug = yearMap['slug'] as String?;
      }
    }

    return ExamModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Exam',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      questionCount: json['questionCount'] as int? ?? 0,
      subjectName: sName ?? json['subjectName'] as String?,
      subjectSlug: sSlug ?? json['subjectSlug'] as String?,
      yearName: yName ?? json['yearName'] as String?,
      yearSlug: ySlug ?? json['yearSlug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationMinutes': durationMinutes,
      'questionCount': questionCount,
      'subject': {
        'name': subjectName,
        'slug': subjectSlug,
        'year': {
          'name': yearName,
          'slug': yearSlug,
        },
      },
    };
  }
}
