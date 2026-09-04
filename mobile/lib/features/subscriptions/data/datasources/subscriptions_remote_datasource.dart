import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_plan_model.dart';
import '../models/user_subscriptions_model.dart';

class SubscriptionsRemoteDataSource {
  final ApiClient _apiClient;

  SubscriptionsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<UserSubscriptionsModel> getUserSubscriptions() async {
    try {
      final response = await _apiClient.client.get('/subscriptions/me');

      if (response.data is Map<String, dynamic>) {
        return UserSubscriptionsModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw const NetworkFailure(
          'Invalid server response loading subscriptions.');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'];
        if (msg is String && msg.isNotEmpty) {
          throw NetworkFailure(msg);
        }
      }
      throw const NetworkFailure('Failed to load user subscriptions.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }

  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    try {
      final response = await _apiClient.client.get('/payments/plans');

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) =>
                SubscriptionPlanModel.fromJson(item as Map<String, dynamic>))
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
      throw const NetworkFailure('Failed to load subscription plans.');
    } catch (e) {
      throw const NetworkFailure('An unexpected error occurred.');
    }
  }
}
