import 'ai_citation.dart';

export 'ai_citation.dart' show AiCitation, ExplainMcqCitation;

class ExplainMcqWhyOther {
  final String option;
  final String explanation;

  const ExplainMcqWhyOther({
    required this.option,
    required this.explanation,
  });

  factory ExplainMcqWhyOther.fromJson(Map<String, dynamic> json) {
    return ExplainMcqWhyOther(
      option: json['option'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class ExplainMcqResponse {
  final String officialAnswer;
  final String selectedAnswer;
  final String? whySelectedWrong;
  final String whyCorrect;
  final List<ExplainMcqWhyOther> whyOtherOptions;
  final String concept;
  final String examTakeaway;
  final double confidence;
  final String grounding;
  final List<AiCitation> citations;
  final String questionQuality;
  final String? questionConcern;

  const ExplainMcqResponse({
    required this.officialAnswer,
    required this.selectedAnswer,
    this.whySelectedWrong,
    required this.whyCorrect,
    required this.whyOtherOptions,
    required this.concept,
    required this.examTakeaway,
    required this.confidence,
    required this.grounding,
    required this.citations,
    required this.questionQuality,
    this.questionConcern,
  });

  factory ExplainMcqResponse.fromJson(Map<String, dynamic> json) {
    final others = <ExplainMcqWhyOther>[];
    if (json['whyOtherOptions'] is List) {
      for (final item in json['whyOtherOptions'] as List) {
        if (item is Map<String, dynamic>) {
          others.add(ExplainMcqWhyOther.fromJson(item));
        }
      }
    }

    final citations = <AiCitation>[];
    if (json['citations'] is List) {
      for (final item in json['citations'] as List) {
        if (item is Map<String, dynamic>) {
          citations.add(AiCitation.fromJson(item));
        }
      }
    }

    return ExplainMcqResponse(
      officialAnswer: json['officialAnswer'] as String? ?? '',
      selectedAnswer: json['selectedAnswer'] as String? ?? '',
      whySelectedWrong: json['whySelectedWrong'] as String?,
      whyCorrect: json['whyCorrect'] as String? ?? '',
      whyOtherOptions: others,
      concept: json['concept'] as String? ?? '',
      examTakeaway: json['examTakeaway'] as String? ?? '',
      confidence: _asDouble(json['confidence']),
      grounding: json['grounding'] as String? ?? 'model',
      citations: citations,
      questionQuality: json['questionQuality'] as String? ?? 'valid',
      questionConcern: json['questionConcern'] as String?,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
