class SubmitAnswerDto {
  final String questionId;
  final String? selectedOptionId;
  final int timeSpentSeconds;

  const SubmitAnswerDto({
    required this.questionId,
    this.selectedOptionId,
    this.timeSpentSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      if (selectedOptionId != null) 'selectedOptionId': selectedOptionId,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

class SubmitExamDto {
  final List<SubmitAnswerDto> answers;

  const SubmitExamDto({
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}
