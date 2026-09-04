import 'exam_question_model.dart';

class ExamStartSessionModel {
  final String attemptId;
  final int durationMinutes;
  final DateTime startedAt;
  final List<ExamQuestionModel> questions;

  const ExamStartSessionModel({
    required this.attemptId,
    required this.durationMinutes,
    required this.startedAt,
    required this.questions,
  });

  factory ExamStartSessionModel.fromJson(Map<String, dynamic> json) {
    var rawQuestions = <ExamQuestionModel>[];
    if (json['questions'] is List) {
      final list = json['questions'] as List;
      rawQuestions = list
          .map((q) => ExamQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    DateTime parsedDate;
    if (json['startedAt'] is String) {
      parsedDate = DateTime.parse(json['startedAt'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    return ExamStartSessionModel(
      attemptId: json['attemptId'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      startedAt: parsedDate,
      questions: rawQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'durationMinutes': durationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
