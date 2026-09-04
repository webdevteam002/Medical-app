class ExamQuestionResultDetail {
  final String questionId;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String explanation;
  final int timeSpentSeconds;

  const ExamQuestionResultDetail({
    required this.questionId,
    this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
    this.timeSpentSeconds = 0,
  });

  factory ExamQuestionResultDetail.fromJson(Map<String, dynamic> json) {
    return ExamQuestionResultDetail(
      questionId: json['questionId'] as String? ?? '',
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
      'selectedOptionId': selectedOptionId,
      'correctOptionId': correctOptionId,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

class ExamSubmitResultModel {
  final int score;
  final int total;
  final double percentage;
  final List<ExamQuestionResultDetail> details;

  const ExamSubmitResultModel({
    required this.score,
    required this.total,
    required this.percentage,
    required this.details,
  });

  factory ExamSubmitResultModel.fromJson(Map<String, dynamic> json) {
    var rawDetails = <ExamQuestionResultDetail>[];
    if (json['details'] is List) {
      final list = json['details'] as List;
      rawDetails = list
          .map((item) =>
              ExamQuestionResultDetail.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ExamSubmitResultModel(
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      details: rawDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'total': total,
      'percentage': percentage,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
