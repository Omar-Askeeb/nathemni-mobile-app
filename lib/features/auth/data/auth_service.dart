import 'package:dio/dio.dart';
import '../../../data/models/api_response.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Register new user
  /// POST /register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post(
        '/register',
        data: {
          'name': name,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => data as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  /// Login with password
  /// POST /login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      // Save token if login successful
      if (apiResponse.success && apiResponse.data?['token'] != null) {
        await _apiClient.setToken(apiResponse.data!['token'] as String);
      }

      return apiResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => data as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  /// Request OTP for login (passwordless)
  /// POST /request-login-otp
  Future<ApiResponse<Map<String, dynamic>>> requestLoginOtp({
    required String identifier,
  }) async {
    try {
      final response = await _apiClient.post(
        '/request-login-otp',
        data: {'identifier': identifier},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => data as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  /// Login with OTP
  /// POST /login-with-otp
  Future<ApiResponse<Map<String, dynamic>>> loginWithOtp({
    required String identifier,
    required String code,
  }) async {
    try {
      final response = await _apiClient.post(
        '/login-with-otp',
        data: {
          'identifier': identifier,
          'code': code,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      // Save token if login successful
      if (apiResponse.success && apiResponse.data?['token'] != null) {
        await _apiClient.setToken(apiResponse.data!['token'] as String);
      }

      return apiResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => data as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  /// Verify OTP (after registration or password reset)
  /// POST /verify-otp
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String identifier,
    required String code,
    required String type, // 'registration', 'login', 'reset'
  }) async {
    try {
      final response = await _apiClient.post(
        '/verify-otp',
        data: {
          'identifier': identifier,
          'code': code,
          'type': type,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      // Save token if OTP verification returns token
      if (apiResponse.success && apiResponse.data?['token'] != null) {
        await _apiClient.setToken(apiResponse.data!['token'] as String);
      }

      return apiResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => data as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }

  /// Get current user
  /// GET /user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/user');

      return ApiResponse.fromJson(
        response.data,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => User.fromJson(data as Map<String, dynamic>),
        );
      }
      rethrow;
    }
  }

  /// Update profile
  /// PUT /profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? language,
  }) async {
    try {
      final response = await _apiClient.put(
        '/profile',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (language != null) 'language': language,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          (data) => User.fromJson(data as Map<String, dynamic>),
        );
      }
      rethrow;
    }
  }

  /// Logout
  /// POST /logout
  Future<ApiResponse<dynamic>> logout() async {
    try {
      final response = await _apiClient.post('/logout');
      await _apiClient.clearToken();

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      await _apiClient.clearToken();
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data, null);
      }
      rethrow;
    }
  }

  /// Change password
  /// POST /change-password
  Future<ApiResponse<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        '/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data, null);
      }
      rethrow;
    }
  }
}
