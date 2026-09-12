import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/explain_mcq_response.dart';

class AiFailure extends Failure {
  final String code;

  const AiFailure(this.code, super.message);
}

class AiChatResponse {
  final String conversationId;
  final String messageId;
  final String reply;
  final String grounding;
  final List<AiCitation> citations;
  final List<String> toolsUsed;
  final String intent;

  const AiChatResponse({
    required this.conversationId,
    required this.messageId,
    required this.reply,
    required this.grounding,
    required this.citations,
    required this.toolsUsed,
    required this.intent,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final citations = <AiCitation>[];
    if (json['citations'] is List) {
      for (final item in json['citations'] as List) {
        if (item is Map<String, dynamic>) {
          citations.add(AiCitation.fromJson(item));
        }
      }
    }
    final tools = <String>[];
    if (json['toolsUsed'] is List) {
      for (final t in json['toolsUsed'] as List) {
        if (t is String) tools.add(t);
      }
    }
    return AiChatResponse(
      conversationId: json['conversationId'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      grounding: json['grounding'] as String? ?? 'model',
      citations: citations,
      toolsUsed: tools,
      intent: json['intent'] as String? ?? '',
    );
  }
}

class AiRemoteDataSource {
  final ApiClient _apiClient;

  AiRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ExplainMcqResponse> explainMcq({
    required String questionId,
    required String selectedOptionId,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '/ai/explain-mcq',
        data: {
          'questionId': questionId,
          'selectedOptionId': selectedOptionId,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return ExplainMcqResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw const AiFailure(
        'AI_INVALID_RESPONSE',
        'Could not load AI explanation.',
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure('Failed to request AI explanation.');
    }
  }

  Future<AiChatResponse> chat({
    required String message,
    String? conversationId,
    String? questionId,
  }) async {
    try {
      final body = <String, dynamic>{'message': message};
      if (conversationId != null && conversationId.isNotEmpty) {
        body['conversationId'] = conversationId;
      }
      if (questionId != null && questionId.isNotEmpty) {
        body['questionId'] = questionId;
      }

      final response = await _apiClient.client.post('/ai/chat', data: body);
      if (response.data is Map<String, dynamic>) {
        return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw const AiFailure(
        'AI_INVALID_RESPONSE',
        'Could not load AI assistant reply.',
      );
    } on DioException catch (e) {
      throw _mapDio(e, chat: true);
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure('Failed to send message to AI assistant.');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiClient.client.delete('/ai/conversations/$conversationId');
    } on DioException catch (e) {
      throw _mapDio(e, chat: true);
    } catch (_) {
      throw const NetworkFailure('Failed to clear conversation.');
    }
  }

  Failure _mapDio(DioException e, {bool chat = false}) {
    final data = e.response?.data;
    String? code;
    String? message;

    if (data is Map) {
      code = data['code'] as String?;
      final msg = data['message'];
      if (msg is String) {
        message = msg;
      } else if (msg is List && msg.isNotEmpty) {
        message = msg.first.toString();
      }
    }

    switch (code) {
      case 'AI_DISABLED':
        return const AiFailure(
          'AI_DISABLED',
          'AI is currently unavailable.',
        );
      case 'AI_QUOTA_EXCEEDED':
        return AiFailure(
          'AI_QUOTA_EXCEEDED',
          chat
              ? 'You have reached today’s AI assistant limit. Try again tomorrow.'
              : 'You have reached today’s AI explanation limit. Try again tomorrow.',
        );
      case 'AI_TIMEOUT':
        return const AiFailure(
          'AI_TIMEOUT',
          'The AI request timed out. Please try again.',
        );
      case 'AI_UNAVAILABLE':
        return const AiFailure(
          'AI_UNAVAILABLE',
          'AI is temporarily unavailable. Please try again.',
        );
      case 'AI_INVALID_RESPONSE':
        return const AiFailure(
          'AI_INVALID_RESPONSE',
          'Could not generate a reliable reply. Please try again.',
        );
      case 'AI_BAD_REQUEST':
        return AiFailure(
          'AI_BAD_REQUEST',
          message ?? 'Unable to process this request.',
        );
      case 'SUBSCRIPTION_REQUIRED':
        return const AiFailure(
          'SUBSCRIPTION_REQUIRED',
          'An active subscription is required for this content.',
        );
      case 'NOT_FOUND':
        return const AiFailure('NOT_FOUND', 'Content not available.');
      default:
        if (message != null && message.isNotEmpty) {
          return NetworkFailure(message);
        }
        return NetworkFailure(
          chat
              ? 'Failed to send message to AI assistant.'
              : 'Failed to request AI explanation.',
        );
    }
  }
}
