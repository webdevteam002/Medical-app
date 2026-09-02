import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/material_access_model.dart';
import '../models/material_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/year_model.dart';

class StudyRemoteDataSource {
  final ApiClient _apiClient;

  StudyRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<YearModel>> getYears() async {
    try {
      final response = await _apiClient.client.get('/years');

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => YearModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load medical education years.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<SubjectModel>> getSubjects(String yearSlug) async {
    try {
      final response = await _apiClient.client.get('/years/$yearSlug/subjects');

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => SubjectModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load subjects for this year.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<TopicModel>> getTopics(String subjectId) async {
    try {
      Response response;
      try {
        response = await _apiClient.client.get('/subjects/$subjectId/topics');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response =
              await _apiClient.client.get('/admin/subjects/$subjectId/topics');
        } else {
          rethrow;
        }
      }

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => TopicModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load topics for this subject.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<MaterialModel>> getMaterials({
    required String subjectId,
    String? topicId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (topicId != null && topicId.isNotEmpty) {
        queryParams['topicId'] = topicId;
      }

      final response = await _apiClient.client.get(
        '/subjects/$subjectId/materials',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => MaterialModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load materials for this topic.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<MaterialAccessModel> getMaterialAccess(String materialId) async {
    try {
      final response =
          await _apiClient.client.get('/materials/$materialId/access');

      if (response.data is Map<String, dynamic>) {
        return MaterialAccessModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw const NetworkFailure('Invalid material access response shape.');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to obtain material access.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }
}
