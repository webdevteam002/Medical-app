import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:medstudy/features/ai/data/models/ai_citation.dart';
import 'package:medstudy/features/ai/presentation/pages/ai_assistant_page.dart';

class _FakeAiRemote extends AiRemoteDataSource {
  _FakeAiRemote({this.failure, this.delay = Duration.zero});

  Failure? failure;
  Duration delay;
  int chatCalls = 0;
  String? lastMessage;
  String? lastConversationId;

  @override
  Future<AiChatResponse> chat({
    required String message,
    String? conversationId,
    String? questionId,
  }) async {
    chatCalls += 1;
    lastMessage = message;
    lastConversationId = conversationId;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failure != null) throw failure!;
    return AiChatResponse(
      conversationId: conversationId ?? 'conv-1',
      messageId: 'm$chatCalls',
      reply: 'Assistant reply for: $message',
      grounding: 'app',
      citations: const [],
      toolsUsed: const ['getAccessibleYears'],
      intent: 'app_help',
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {}
}

void main() {
  testWidgets('assistant screen renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiAssistantPage(aiRemoteDataSource: _FakeAiRemote()),
      ),
    );
    expect(find.text('MedStudy AI Assistant'), findsOneWidget);
    expect(find.textContaining('Educational AI Assistant'), findsOneWidget);
    expect(find.byKey(const Key('ai_assistant_input')), findsOneWidget);
  });

  testWidgets('sending a message shows loading then reply', (tester) async {
    final fake = _FakeAiRemote(delay: const Duration(milliseconds: 40));
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );

    await tester.enterText(
      find.byKey(const Key('ai_assistant_input')),
      'Which subjects are available for Year 1?',
    );
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pump();
    expect(find.byKey(const Key('ai_assistant_loading')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('ai_assistant_send')))
          .onPressed,
      isNull,
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_assistant_bot_bubble')), findsOneWidget);
    expect(find.textContaining('Assistant reply'), findsOneWidget);
    expect(fake.chatCalls, 1);
  });

  testWidgets('follow-up keeps conversation id', (tester) async {
    final fake = _FakeAiRemote();
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );

    await tester.enterText(find.byKey(const Key('ai_assistant_input')),
        'What is nephrotic syndrome?');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('ai_assistant_input')), 'What causes it?');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();

    expect(fake.chatCalls, 2);
    expect(fake.lastConversationId, 'conv-1');
  });

  testWidgets('AI disabled error', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure('AI_DISABLED', 'AI is currently unavailable.'),
    );
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(find.byKey(const Key('ai_assistant_input')), 'Hi');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_assistant_error')), findsOneWidget);
    expect(find.byKey(const Key('ai_assistant_retry')), findsNothing);
  });

  testWidgets('quota exceeded', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure(
        'AI_QUOTA_EXCEEDED',
        'You have reached today’s AI assistant limit. Try again tomorrow.',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(find.byKey(const Key('ai_assistant_input')), 'Hi');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('assistant limit'), findsOneWidget);
  });

  testWidgets('timeout shows retry', (tester) async {
    final fake = _FakeAiRemote(
      failure: const AiFailure(
        'AI_TIMEOUT',
        'The AI request timed out. Please try again.',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(find.byKey(const Key('ai_assistant_input')), 'Hi');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_assistant_retry')), findsOneWidget);
  });

  testWidgets('duplicate send prevention while loading', (tester) async {
    final fake = _FakeAiRemote(delay: const Duration(milliseconds: 200));
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(find.byKey(const Key('ai_assistant_input')), 'Hi');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pump();
    expect(fake.chatCalls, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('new conversation clears bubbles', (tester) async {
    final fake = _FakeAiRemote();
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(find.byKey(const Key('ai_assistant_input')), 'Hi');
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_assistant_bot_bubble')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai_assistant_new')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ai_assistant_bot_bubble')), findsNothing);
  });

  testWidgets('RAG reply shows Sources; non-RAG does not invent sources',
      (tester) async {
    final fake = _RagFakeAiRemote();
    await tester.pumpWidget(
      MaterialApp(home: AiAssistantPage(aiRemoteDataSource: fake)),
    );
    await tester.enterText(
      find.byKey(const Key('ai_assistant_input')),
      'Explain nephrotic syndrome',
    );
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.text('Sources'), findsOneWidget);
    expect(find.textContaining('Renal Notes'), findsOneWidget);
    expect(find.textContaining('Pages 3–4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai_assistant_new')));
    await tester.pumpAndSettle();
    fake.withCitations = false;
    await tester.enterText(
      find.byKey(const Key('ai_assistant_input')),
      'How do exams work?',
    );
    await tester.tap(find.byKey(const Key('ai_assistant_send')));
    await tester.pumpAndSettle();
    expect(find.text('Sources'), findsNothing);
    expect(find.textContaining('Grounding: app'), findsOneWidget);
  });
}

class _RagFakeAiRemote extends AiRemoteDataSource {
  bool withCitations = true;

  @override
  Future<AiChatResponse> chat({
    required String message,
    String? conversationId,
    String? questionId,
  }) async {
    if (!withCitations) {
      return AiChatResponse(
        conversationId: conversationId ?? 'conv-1',
        messageId: 'm-app',
        reply: 'App help reply',
        grounding: 'app',
        citations: const [],
        toolsUsed: const ['getAppHelp'],
        intent: 'app_help',
      );
    }
    return AiChatResponse(
      conversationId: conversationId ?? 'conv-1',
      messageId: 'm-rag',
      reply: 'Nephrotic syndrome involves heavy proteinuria.',
      grounding: 'rag',
      citations: const [
        AiCitation(
          materialId: 'm1',
          title: 'Renal Notes',
          subjectName: 'Medicine',
          pageStart: 3,
          pageEnd: 4,
          chunkId: 'c1',
          documentId: 'd1',
          contentHash: 'hv1',
        ),
      ],
      toolsUsed: const [],
      intent: 'content',
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {}
}
