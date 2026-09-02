import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_tokens.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AuthTokens> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthTokens.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw const NetworkFailure('Unexpected response from server.');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        String message = 'Invalid email or password.';
        if (data is Map<String, dynamic> && data['message'] != null) {
          if (data['message'] is String) {
            message = data['message'] as String;
          } else if (data['message'] is List &&
              (data['message'] as List).isNotEmpty) {
            message = (data['message'] as List).first.toString();
          }
        }

        if (statusCode == 401 || statusCode == 403) {
          throw NetworkFailure(message);
        } else {
          throw NetworkFailure('Server error ($statusCode). Please try again.');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure(
            'Connection timeout. Please check your internet connection.');
      } else {
        throw const NetworkFailure(
            'Unable to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String fullName,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim().isEmpty ? 'Student' : fullName.trim(),
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthTokens.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw const NetworkFailure('Unexpected response from server.');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        String message = 'Registration failed. Please try again.';
        if (data is Map<String, dynamic> && data['message'] != null) {
          if (data['message'] is String) {
            message = data['message'] as String;
          } else if (data['message'] is List &&
              (data['message'] as List).isNotEmpty) {
            message = (data['message'] as List).first.toString();
          }
        }

        if (statusCode == 409) {
          throw NetworkFailure(message);
        } else if (statusCode == 400) {
          throw NetworkFailure(message);
        } else {
          throw NetworkFailure('Server error ($statusCode). Please try again.');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure(
            'Connection timeout. Please check your internet connection.');
      } else {
        throw const NetworkFailure(
            'Unable to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('An unexpected error occurred: ${e.toString()}');
    }
  }
}
