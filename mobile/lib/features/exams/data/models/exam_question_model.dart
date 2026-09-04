import 'question_option_model.dart';

class ExamQuestionModel {
  final String id;
  final String stem;
  final List<QuestionOptionModel> options;
  final String? imageKey;

  const ExamQuestionModel({
    required this.id,
    required this.stem,
    required this.options,
    this.imageKey,
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = <QuestionOptionModel>[];
    if (json['options'] is List) {
      final list = json['options'] as List;
      rawOptions = list
          .map((opt) =>
              QuestionOptionModel.fromJson(opt as Map<String, dynamic>))
          .toList();
    }

    return ExamQuestionModel(
      id: json['id'] as String? ?? '',
      stem: json['stem'] as String? ?? '',
      options: rawOptions,
      imageKey: json['imageKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stem': stem,
      'options': options.map((o) => o.toJson()).toList(),
      'imageKey': imageKey,
    };
  }
}
