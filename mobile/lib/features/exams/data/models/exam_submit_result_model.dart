class ExamOptionModel {
  final String id;
  final String text;

  const ExamOptionModel({required this.id, required this.text});

  factory ExamOptionModel.fromJson(Map<String, dynamic> json) {
    return ExamOptionModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class ExamQuestionResultDetail {
  final String questionId;
  final String stem;
  final List<ExamOptionModel> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String explanation;
  final int timeSpentSeconds;
  final String gradedBy;

  const ExamQuestionResultDetail({
    required this.questionId,
    this.stem = '',
    this.options = const [],
    this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
    this.timeSpentSeconds = 0,
    this.gradedBy = 'key',
  });

  factory ExamQuestionResultDetail.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    final options = optionsRaw is List
        ? optionsRaw
            .whereType<Map>()
            .map((o) => ExamOptionModel.fromJson(Map<String, dynamic>.from(o)))
            .toList()
        : <ExamOptionModel>[];

    return ExamQuestionResultDetail(
      questionId: json['questionId'] as String? ?? '',
      stem: json['stem'] as String? ?? '',
      options: options,
      selectedOptionId: json['selectedOptionId'] as String?,
      correctOptionId: json['correctOptionId'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      gradedBy: json['gradedBy'] as String? ?? 'key',
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
      'gradedBy': gradedBy,
    };
  }
}

class ExamSubmitResultModel {
  final String attemptId;
  final int score;
  final int total;
  final double percentage;
  final String gradedBy;
  final List<ExamQuestionResultDetail> details;

  const ExamSubmitResultModel({
    this.attemptId = '',
    required this.score,
    required this.total,
    required this.percentage,
    this.gradedBy = 'key',
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
      attemptId: json['attemptId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      percentage: _parseDouble(json['percentage']),
      gradedBy: json['gradedBy'] as String? ?? 'key',
      details: rawDetails,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'score': score,
      'total': total,
      'percentage': percentage,
      'gradedBy': gradedBy,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
