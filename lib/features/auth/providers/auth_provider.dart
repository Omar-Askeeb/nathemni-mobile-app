import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_client.dart';
import '../data/auth_service.dart';
import 'auth_state.dart';

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

/// Provider for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Provider for current user (convenience provider)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthInitial());

  /// Hash password for local storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authService.getLocalCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user);
          return;
        }
      }

      // Check if user needs to register
      final hasRegistered = await _authService.hasRegisteredUser();
      state = AuthUnauthenticated(needsRegistration: !hasRegistered);
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      state = AuthUnauthenticated(needsRegistration: true);
    }
  }

  /// Register new user
  Future<bool> register({
    required String nameAr,
    required String nameEn,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      // Try online registration first
      final response = await _authService.register(
        nameAr: nameAr,
        nameEn: nameEn,
        username: username,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: password,
      );

      if (response.success) {
        // Online registration successful - also save locally and auto-login
        final user = await _authService.registerLocally(
          nameAr: nameAr,
          nameEn: nameEn,
          username: username,
          email: email,
          phone: phone,
          passwordHash: _hashPassword(password),
        );
        state = AuthAuthenticated(user);
        return true;
      }
      // If online failed, fall through to local registration
    } catch (e) {
      debugPrint('Online registration failed: $e');
    }

    // Fallback to local-only registration
    try {
      final user = await _authService.registerLocally(
        nameAr: nameAr,
        nameEn: nameEn,
        username: username,
        email: email,
        phone: phone,
        passwordHash: _hashPassword(password),
      );

      // Auto-login after local registration
      state = AuthAuthenticated(user);
      return true;
    } catch (localError) {
      state = AuthError('فشل التسجيل: $localError');
      return false;
    }
  }

  /// Login with identifier (email or phone) and password
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      // Try online login first
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (response.success) {
        final user = await _authService.getLocalCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user);
          return true;
        }
      }
      
      // Always show Arabic error message for login failures
      state = const AuthError('بيانات الدخول غير صحيحة');
      return false;
    } catch (e) {
      debugPrint('Online login failed, trying offline: $e');
      
      // Fallback to offline login
      try {
        final user = await _authService.loginLocally(
          identifier: identifier,
          passwordHash: _hashPassword(password),
        );

        if (user != null) {
          state = AuthAuthenticated(user);
          return true;
        } else {
          state = const AuthError('بيانات الدخول غير صحيحة');
          return false;
        }
      } catch (localError) {
        state = const AuthError('فشل تسجيل الدخول، تأكد من بياناتك');
        return false;
      }
    }
  }

  /// Logout - sets state to unauthenticated immediately for smooth navigation
  Future<void> logout() async {
    // Set unauthenticated state immediately for instant UI update
    state = const AuthUnauthenticated(needsRegistration: false);

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Online logout failed: $e');
      await _authService.logoutLocally();
    }
  }

  /// Update user in state
  void updateUser(User user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }

  /// Clear error and return to unauthenticated
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated(needsRegistration: false);
    }
  }

  /// Change password (offline-first)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;

    try {
      // Try online first
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPassword,
      );

      if (response.success) {
        // Also update locally for offline login
        await _authService.changePasswordLocally(
          userId: user.id,
          oldPasswordHash: _hashPassword(currentPassword),
          newPasswordHash: _hashPassword(newPassword),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Online password change failed, trying offline: $e');
      
      // Fallback to offline
      return await _authService.changePasswordLocally(
        userId: user.id,
        oldPasswordHash: _hashPassword(currentPassword),
        newPasswordHash: _hashPassword(newPassword),
      );
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;

    try {
      final success = await _authService.deleteAccountLocally(user.id);
      if (success) {
        state = const AuthUnauthenticated(needsRegistration: true);
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}
