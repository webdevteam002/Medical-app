import 'question_option_model.dart';

class ExamReviewDetailModel {
  final String questionId;
  final String stem;
  final List<QuestionOptionModel> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String explanation;
  final int timeSpentSeconds;

  const ExamReviewDetailModel({
    required this.questionId,
    required this.stem,
    required this.options,
    this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
    this.timeSpentSeconds = 0,
  });

  factory ExamReviewDetailModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = <QuestionOptionModel>[];
    if (json['options'] is List) {
      final list = json['options'] as List;
      rawOptions = list
          .map((opt) =>
              QuestionOptionModel.fromJson(opt as Map<String, dynamic>))
          .toList();
    }

    return ExamReviewDetailModel(
      questionId: json['questionId'] as String? ?? '',
      stem: json['stem'] as String? ?? '',
      options: rawOptions,
      selectedOptionId: json['selectedOptionId'] as String?,
      correctOptionId: json['correctOptionId'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'stem': stem,
      'options': options.map((o) => o.toJson()).toList(),
      'selectedOptionId': selectedOptionId,
      'correctOptionId': correctOptionId,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

class ExamAttemptReviewModel {
  final String id;
  final String examTitle;
  final int score;
  final int total;
  final double percentage;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<ExamReviewDetailModel> details;

  const ExamAttemptReviewModel({
    required this.id,
    required this.examTitle,
    required this.score,
    required this.total,
    required this.percentage,
    required this.startedAt,
    required this.completedAt,
    required this.details,
  });

  factory ExamAttemptReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.parse(val);
      }
      return DateTime.now();
    }

    var rawDetails = <ExamReviewDetailModel>[];
    if (json['details'] is List) {
      final list = json['details'] as List;
      rawDetails = list
          .map((item) =>
              ExamReviewDetailModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ExamAttemptReviewModel(
      id: json['id'] as String? ?? '',
      examTitle: json['examTitle'] as String? ?? 'Exam Review',
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
      details: rawDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examTitle': examTitle,
      'score': score,
      'total': total,
      'percentage': percentage,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
