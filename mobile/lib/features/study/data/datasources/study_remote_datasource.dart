import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/bookmarked_material_model.dart';
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
    String? searchQuery,
    bool? pastPapersOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (topicId != null && topicId.isNotEmpty) {
        queryParams['topicId'] = topicId;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }
      if (pastPapersOnly == true) {
        queryParams['pastPapersOnly'] = 'true';
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
      throw const NetworkFailure('Failed to load materials.');
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

  Future<bool> addBookmark(String materialId) async {
    try {
      final response =
          await _apiClient.client.post('/bookmarks/$materialId');

      if (response.data is Map<String, dynamic>) {
        final success = response.data['success'];
        if (success == true) return true;
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to bookmark material.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<bool> removeBookmark(String materialId) async {
    try {
      final response =
          await _apiClient.client.delete('/bookmarks/$materialId');

      if (response.data is Map<String, dynamic>) {
        final success = response.data['success'];
        if (success == true) return true;
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to remove material bookmark.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<BookmarkedMaterialModel>> getBookmarks() async {
    try {
      final response = await _apiClient.client.get('/bookmarks');

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) =>
                BookmarkedMaterialModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load bookmarked materials.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }
}
