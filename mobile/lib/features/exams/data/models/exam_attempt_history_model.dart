class ExamAttemptHistoryModel {
  final String id;
  final String examTitle;
  final String subjectName;
  final int score;
  final int total;
  final double percentage;
  final DateTime startedAt;
  final DateTime completedAt;

  const ExamAttemptHistoryModel({
    required this.id,
    required this.examTitle,
    required this.subjectName,
    required this.score,
    required this.total,
    required this.percentage,
    required this.startedAt,
    required this.completedAt,
  });

  factory ExamAttemptHistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.parse(val);
      }
      return DateTime.now();
    }

    return ExamAttemptHistoryModel(
      id: json['id'] as String? ?? '',
      examTitle: json['examTitle'] as String? ?? 'Untitled Exam',
      subjectName: json['subjectName'] as String? ?? 'General',
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examTitle': examTitle,
      'subjectName': subjectName,
      'score': score,
      'total': total,
      'percentage': percentage,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
