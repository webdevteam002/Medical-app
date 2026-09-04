import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/exam_attempt_history_model.dart';
import '../models/exam_attempt_review_model.dart';
import '../models/exam_model.dart';
import '../models/exam_start_session_model.dart';
import '../models/exam_submit_result_model.dart';
import '../models/submit_exam_dto.dart';

class ExamsRemoteDataSource {
  final ApiClient _apiClient;

  ExamsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<ExamModel>> getExams({
    String? yearSlug,
    String? subjectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (yearSlug != null && yearSlug.isNotEmpty) {
        queryParams['yearSlug'] = yearSlug;
      }
      if (subjectId != null && subjectId.isNotEmpty) {
        queryParams['subjectId'] = subjectId;
      }

      final response = await _apiClient.client.get(
        '/exams',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => ExamModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to load published exams.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<ExamStartSessionModel> startExam(String examId) async {
    try {
      final response = await _apiClient.client.post('/exams/$examId/start');

      if (response.data is Map<String, dynamic>) {
        return ExamStartSessionModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw const NetworkFailure('Invalid server response starting exam.');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to start exam session.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<ExamSubmitResultModel> submitExam(
    String attemptId,
    SubmitExamDto dto,
  ) async {
    try {
      final response = await _apiClient.client.post(
        '/exams/attempts/$attemptId/submit',
        data: dto.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return ExamSubmitResultModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw const NetworkFailure('Invalid server response submitting exam.');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to submit exam.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<ExamAttemptHistoryModel>> getExamAttempts() async {
    try {
      final response = await _apiClient.client.get('/exams/attempts');

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) =>
                ExamAttemptHistoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to load exam attempt history.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<ExamAttemptReviewModel> getAttemptReview(String attemptId) async {
    try {
      final response =
          await _apiClient.client.get('/exams/attempts/$attemptId');

      if (response.data is Map<String, dynamic>) {
        return ExamAttemptReviewModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw const NetworkFailure(
          'Invalid server response loading attempt review.');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to load exam attempt review.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }
}
