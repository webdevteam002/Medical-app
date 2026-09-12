import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:medstudy/features/ai/data/models/explain_mcq_response.dart';
import 'package:medstudy/features/ai/presentation/widgets/mcq_ai_explain_panel.dart';
import 'package:medstudy/features/ai/presentation/widgets/ai_sources_section.dart';
import 'package:medstudy/features/exams/data/models/exam_attempt_review_model.dart';
import 'package:medstudy/features/exams/data/models/question_option_model.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_review_page.dart';

class _FakeAiRemote extends AiRemoteDataSource {
  _FakeAiRemote({
    this.response,
    this.failure,
    this.delay = Duration.zero,
  });

  final ExplainMcqResponse? response;
  final Failure? failure;
  final Duration delay;
  int callCount = 0;
  String? lastQuestionId;
  String? lastSelectedOptionId;

  @override
  Future<ExplainMcqResponse> explainMcq({
    required String questionId,
    required String selectedOptionId,
  }) async {
    callCount += 1;
    lastQuestionId = questionId;
    lastSelectedOptionId = selectedOptionId;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failure != null) {
      throw failure!;
    }
    return response!;
  }
}

ExplainMcqResponse _sample({
  String? whySelectedWrong = 'Wrong territory.',
  String questionQuality = 'valid',
  String? questionConcern,
  List<AiCitation> citations = const [
    AiCitation(
      materialId: 'm1',
      title: 'Anatomy Notes',
      subjectName: 'Anatomy',
      pageStart: 12,
      pageEnd: 12,
      chunkId: 'c1',
      documentId: 'd1',
      contentHash: 'hash-a',
    ),
  ],
  String grounding = 'rag',
}) {
  return ExplainMcqResponse(
    officialAnswer: 'Femoral artery',
    selectedAnswer: 'Obturator artery',
    whySelectedWrong: whySelectedWrong,
    whyCorrect: 'Femoral supplies the anterior thigh.',
    whyOtherOptions: const [
      ExplainMcqWhyOther(
        option: 'Popliteal artery',
        explanation: 'Too distal.',
      ),
    ],
    concept: 'Lower limb arterial supply',
    examTakeaway: 'Map vessel to compartment.',
    confidence: 0.9,
    grounding: grounding,
    citations: citations,
    questionQuality: questionQuality,
    questionConcern: questionConcern,
  );
}

ExamAttemptReviewModel _review({
  bool isCorrect = false,
  String? selectedOptionId = 'b',
}) {
  return ExamAttemptReviewModel(
    id: 'att_ai',
    examTitle: 'AI Review Exam',
    score: isCorrect ? 1 : 0,
    total: 1,
    percentage: isCorrect ? 100 : 0,
    startedAt: DateTime.now(),
    completedAt: DateTime.now(),
    details: [
      ExamReviewDetailModel(
        questionId: 'q-ai-1',
        stem: 'Which artery supplies the anterior thigh?',
        options: const [
          QuestionOptionModel(id: 'a', text: 'Femoral artery'),
          QuestionOptionModel(id: 'b', text: 'Obturator artery'),
        ],
        selectedOptionId: selectedOptionId,
        correctOptionId: 'a',
        isCorrect: isCorrect,
        explanation: 'Official key explanation.',
      ),
    ],
  );
}

Widget _panel({
  required _FakeAiRemote fake,
  bool isCorrect = false,
  String? selectedOptionId = 'b',
  VoidCallback? onAskAboutQuestion,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: McqAiExplainPanel(
          questionId: 'q-ai-1',
          selectedOptionId: selectedOptionId,
          selectedOptionLabel: (selectedOptionId ?? '—').toUpperCase(),
          selectedOptionText:
              selectedOptionId == 'a' ? 'Femoral artery' : 'Obturator artery',
          correctOptionLabel: 'A',
          correctOptionText: 'Femoral artery',
          isCorrect: isCorrect,
          aiRemoteDataSource: fake,
          onAskAboutQuestion: onAskAboutQuestion,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('AI auto-loads on exam review and shows ask follow-up',
      (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(),
      delay: const Duration(milliseconds: 40),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExamReviewPage(
          attemptId: 'att_ai',
          initialReview: _review(),
          aiRemoteDataSource: fake,
        ),
      ),
    );

    await tester.pump(); // post-frame callback schedules request
    await tester.pump(); // loading UI
    expect(find.byKey(const Key('ai_explain_loading')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai_explain_result')), findsOneWidget);
    expect(find.text('Ask about this question'), findsOneWidget);
    expect(
      find.byKey(const Key('ask_ai_about_question_button')),
      findsOneWidget,
    );
    expect(find.text('Ask AI to Explain'), findsNothing);
    expect(fake.callCount, 1);
  });

  testWidgets('loading and successful incorrect explanation auto-loads',
      (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(),
      delay: const Duration(milliseconds: 50),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pump();
    expect(find.byKey(const Key('ai_explain_loading')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_explain_result')), findsOneWidget);
    expect(find.text('Why Your Answer Is Wrong'), findsOneWidget);
    expect(find.textContaining('Wrong territory.'), findsOneWidget);
    expect(find.text('Core Concept'), findsOneWidget);
    expect(find.text('Exam Takeaway'), findsOneWidget);
    expect(find.textContaining('Anatomy Notes'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
    expect(find.textContaining('Page 12'), findsOneWidget);
    expect(find.byType(AiSourcesSection), findsOneWidget);
    expect(fake.callCount, 1);
    expect(fake.lastQuestionId, 'q-ai-1');
    expect(fake.lastSelectedOptionId, 'b');
  });

  testWidgets('ask about this question invokes callback', (tester) async {
    var tapped = false;
    final fake = _FakeAiRemote(response: _sample());
    await tester.pumpWidget(
      _panel(
        fake: fake,
        onAskAboutQuestion: () => tapped = true,
      ),
    );
    await tester.pumpAndSettle();
    final askButton = find.byKey(const Key('ask_ai_about_question_button'));
    await tester.ensureVisible(askButton);
    await tester.pumpAndSettle();
    await tester.tap(askButton);
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('no Sources section when citations empty', (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(citations: const [], grounding: 'model'),
    );
    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();
    expect(find.text('Sources'), findsNothing);
    expect(find.textContaining('Grounding: model'), findsOneWidget);
  });

  testWidgets('missing page metadata is not invented', (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(
        citations: const [
          AiCitation(
            materialId: 'm1',
            title: 'Pharmacology Notes',
            subjectName: 'Pharmacology',
            chunkId: 'c2',
            documentId: 'd2',
          ),
        ],
      ),
    );
    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pharmacology Notes'), findsOneWidget);
    expect(find.textContaining('Page '), findsNothing);
  });

  testWidgets('correct answer presentation omits wrong-reason section',
      (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(whySelectedWrong: null),
    );

    await tester.pumpWidget(
      _panel(fake: fake, isCorrect: true, selectedOptionId: 'a'),
    );

    await tester.pumpAndSettle();

    expect(find.text('Why Your Answer Is Correct'), findsOneWidget);
    expect(find.text('Why Your Answer Is Wrong'), findsNothing);
  });

  testWidgets('AI disabled state', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure(
        'AI_DISABLED',
        'AI explanations are currently unavailable.',
      ),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai_explain_error')), findsOneWidget);
    expect(
      find.text('AI explanations are currently unavailable.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ai_explain_retry')), findsNothing);
  });

  testWidgets('quota error', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure(
        'AI_QUOTA_EXCEEDED',
        'You have reached today’s AI explanation limit. Try again tomorrow.',
      ),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('AI explanation limit'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ai_explain_retry')), findsNothing);
  });

  testWidgets('timeout shows retry', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure(
        'AI_TIMEOUT',
        'The AI request timed out. Please try again.',
      ),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai_explain_retry')), findsOneWidget);
  });

  testWidgets('duplicate auto-request prevention while loading',
      (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(),
      delay: const Duration(milliseconds: 200),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pump();
    expect(fake.callCount, 1);
    await tester.pumpAndSettle();
    expect(fake.callCount, 1);
  });

  testWidgets('quality warning presentation', (tester) async {
    final fake = _FakeAiRemote(
      response: _sample(
        questionQuality: 'ambiguous',
        questionConcern: 'Wording may allow more than one interpretation.',
      ),
    );

    await tester.pumpWidget(_panel(fake: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai_quality_warning')), findsOneWidget);
    expect(
      find.textContaining('more than one interpretation'),
      findsOneWidget,
    );
  });

  test('ExplainMcqResponse parses server JSON', () {
    final parsed = ExplainMcqResponse.fromJson({
      'officialAnswer': 'A',
      'selectedAnswer': 'B',
      'whySelectedWrong': 'No',
      'whyCorrect': 'Yes',
      'whyOtherOptions': [
        {'option': 'C', 'explanation': 'Nope'},
      ],
      'concept': 'Concept',
      'examTakeaway': 'Takeaway',
      'confidence': 0.5,
      'grounding': 'key',
      'citations': [],
      'questionQuality': 'valid',
      'questionConcern': null,
    });
    expect(parsed.whyOtherOptions.length, 1);
    expect(parsed.grounding, 'key');
  });
}
