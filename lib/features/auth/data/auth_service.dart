import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/api_response.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/user_repository.dart';

class AuthService {
  final ApiClient _apiClient;
  final UserRepository _userRepository;
  final FlutterSecureStorage _secureStorage;

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserIdKey = 'current_user_id';

  AuthService(
    this._apiClient, {
    UserRepository? userRepository,
    FlutterSecureStorage? secureStorage,
  })  : _userRepository = userRepository ?? UserRepository(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
    return isLoggedIn == 'true';
  }

  /// Get current user ID from secure storage
  Future<int?> getCurrentUserId() async {
    final userId = await _secureStorage.read(key: _currentUserIdKey);
    return userId != null ? int.tryParse(userId) : null;
  }

  /// Set login state
  Future<void> _setLoggedIn(bool value, {int? userId}) async {
    await _secureStorage.write(key: _isLoggedInKey, value: value.toString());
    if (userId != null) {
      await _secureStorage.write(key: _currentUserIdKey, value: userId.toString());
    } else if (!value) {
      await _secureStorage.delete(key: _currentUserIdKey);
    }
  }

  /// Register new user
  /// POST /register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String nameAr,
    required String nameEn,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post(
        '/register',
        data: {
          'name': nameAr, // Use Arabic name as primary name
          'name_ar': nameAr,
          'name_en': nameEn,
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      // If registration successful, save user locally
      if (apiResponse.success && apiResponse.data != null) {
        final userData = apiResponse.data!['user'] as Map<String, dynamic>?;
        if (userData != null) {
          var user = User.fromJson(userData);
          // Merge with registration data to ensure fields like nameAr/nameEn are preserved
          // if the server response is incomplete
          user = user.copyWith(
            nameAr: user.nameAr ?? nameAr,
            nameEn: user.nameEn ?? nameEn,
            username: user.username ?? username,
            email: user.email ?? email,
            phone: user.phone ?? phone,
          );
          await _userRepository.saveUser(user);
          await _setLoggedIn(true, userId: user.id);
        }
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

  /// Register user locally (offline mode)
  Future<User> registerLocally({
    required String nameAr,
    required String nameEn,
    required String username,
    required String email,
    required String phone,
    required String passwordHash,
  }) async {
    final user = await _userRepository.createUser(
      name: nameAr,
      nameAr: nameAr,
      nameEn: nameEn,
      username: username,
      email: email,
      phone: phone,
    );
    
    // Store password hash for offline login
    await _userRepository.setPasswordHash(user.id, passwordHash);
    
    // Auto-login after local registration
    await _setLoggedIn(true, userId: user.id);
    
    return user;
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

      // Save token and set logged in state if login successful
      if (apiResponse.success && apiResponse.data?['token'] != null) {
        await _apiClient.setToken(apiResponse.data!['token'] as String);
        
        // Save user data locally and set logged in
        final userData = apiResponse.data!['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final user = User.fromJson(userData);
          await _userRepository.saveUser(user);
          await _setLoggedIn(true, userId: user.id);
        }
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

  /// Login locally (offline mode)
  Future<User?> loginLocally({
    required String identifier,
    required String passwordHash,
  }) async {
    final user = await _userRepository.validateLogin(identifier, passwordHash);
    if (user != null) {
      await _setLoggedIn(true, userId: user.id);
    }
    return user;
  }

  /// Get current logged in user from local storage
  Future<User?> getLocalCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    return await _userRepository.getUser(userId);
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
    String? nameAr,
    String? nameEn,
    String? username,
    String? email,
    String? phone,
    String? language,
  }) async {
    try {
      final response = await _apiClient.put(
        '/profile',
        data: {
          if (nameAr != null) 'name': nameAr,
          if (nameAr != null) 'name_ar': nameAr,
          if (nameEn != null) 'name_en': nameEn,
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (language != null) 'language': language,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        // Merge server response with the data we just successfully sent
        // This is crucial because the server might return a partial user object
        final updatedUser = apiResponse.data!.copyWith(
          nameAr: nameAr ?? apiResponse.data!.nameAr,
          nameEn: nameEn ?? apiResponse.data!.nameEn,
          username: username ?? apiResponse.data!.username,
          email: email ?? apiResponse.data!.email,
          phone: phone ?? apiResponse.data!.phone,
          language: language ?? apiResponse.data!.language,
        );
        
        final mergedUser = await _userRepository.saveUser(updatedUser);
        return apiResponse.copyWith(data: mergedUser);
      }

      return apiResponse;
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

  /// Update profile locally (offline mode)
  Future<User?> updateProfileLocally({
    required int userId,
    String? nameAr,
    String? nameEn,
    String? username,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    final user = await _userRepository.getUser(userId);
    if (user == null) return null;

    final updatedUser = user.copyWith(
      name: nameAr ?? user.name,
      nameAr: nameAr ?? user.nameAr,
      nameEn: nameEn ?? user.nameEn,
      username: username ?? user.username,
      email: email ?? user.email,
      phone: phone ?? user.phone,
      profileImage: profileImage ?? user.profileImage,
    );

    await _userRepository.updateUser(updatedUser);
    return updatedUser;
  }

  /// Upload profile image
  /// POST /profile/image
  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage(String filePath) async {
    try {
      final response = await _apiClient.uploadFile(
        '/profile/image',
        filePath,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      // Update local user with new image URL
      if (apiResponse.success && apiResponse.data?['image_url'] != null) {
        final userId = await getCurrentUserId();
        if (userId != null) {
          await _userRepository.updateProfileImage(
            userId,
            apiResponse.data!['image_url'] as String,
          );
        }
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

  /// Update profile image locally (for offline use)
  Future<void> updateProfileImageLocally(int userId, String imagePath) async {
    await _userRepository.updateProfileImage(userId, imagePath);
  }

  /// Logout
  /// POST /logout
  Future<ApiResponse<dynamic>> logout() async {
    try {
      final response = await _apiClient.post('/logout');
      await _apiClient.clearToken();
      await _setLoggedIn(false);

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      await _apiClient.clearToken();
      await _setLoggedIn(false);
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data, null);
      }
      rethrow;
    }
  }

  /// Logout locally (offline mode)
  Future<void> logoutLocally() async {
    await _apiClient.clearToken();
    await _setLoggedIn(false);
  }

  /// Check if user has registered (has a profile)
  Future<bool> hasRegisteredUser() async {
    return await _userRepository.hasRegisteredUser();
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

  /// Change password locally (offline mode)
  Future<bool> changePasswordLocally({
    required int userId,
    required String oldPasswordHash,
    required String newPasswordHash,
  }) async {
    return await _userRepository.changePassword(
      userId,
      oldPasswordHash,
      newPasswordHash,
    );
  }

  /// Delete user account locally
  Future<bool> deleteAccountLocally(int userId) async {
    final success = await _userRepository.deleteUserAccount(userId);
    if (success) {
      await _apiClient.clearToken();
      await _setLoggedIn(false);
    }
    return success;
  }
}
