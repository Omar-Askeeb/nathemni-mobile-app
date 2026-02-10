import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/auth_service.dart';

/// Profile state
class ProfileState {
  final User? user;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  ProfileState copyWith({
    User? user,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }
}

/// Profile notifier for managing profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthService _authService;
  final Ref _ref;

  ProfileNotifier(this._authService, this._ref) : super(const ProfileState());

  /// Load current user profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.getLocalCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      state = state.copyWith(isLoading: false, error: 'فشل تحميل الملف الشخصي');
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? nameAr,
    String? nameEn,
    String? username,
    String? email,
    String? phone,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isUpdating: true, error: null);

    try {
      // Try online update first
      final response = await _authService.updateProfile(
        nameAr: nameAr,
        nameEn: nameEn,
        username: username,
        email: email,
        phone: phone,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(user: response.data, isUpdating: false);
        _ref.read(authStateProvider.notifier).updateUser(response.data!);
        return true;
      }

      state = state.copyWith(
        isUpdating: false,
        error: response.message ?? 'فشل تحديث الملف الشخصي',
      );
      return false;
    } catch (e) {
      debugPrint('Online profile update failed, trying offline: $e');

      // Fallback to offline update
      try {
        final updatedUser = await _authService.updateProfileLocally(
          userId: state.user!.id,
          nameAr: nameAr,
          nameEn: nameEn,
          username: username,
          email: email,
          phone: phone,
        );

        if (updatedUser != null) {
          state = state.copyWith(user: updatedUser, isUpdating: false);
          _ref.read(authStateProvider.notifier).updateUser(updatedUser);
          return true;
        }

        state = state.copyWith(isUpdating: false, error: 'فشل تحديث الملف الشخصي');
        return false;
      } catch (localError) {
        state = state.copyWith(
          isUpdating: false,
          error: 'فشل تحديث الملف الشخصي: $localError',
        );
        return false;
      }
    }
  }

  /// Update profile image
  Future<bool> updateProfileImage(XFile imageFile) async {
    if (state.user == null) return false;

    state = state.copyWith(isUpdating: true, error: null);

    try {
      // Try online upload first
      final response = await _authService.uploadProfileImage(imageFile.path);

      if (response.success && response.data?['image_url'] != null) {
        final updatedUser = state.user!.copyWith(
          profileImage: response.data!['image_url'] as String,
        );
        state = state.copyWith(user: updatedUser, isUpdating: false);
        _ref.read(authStateProvider.notifier).updateUser(updatedUser);
        return true;
      }

      // Fall through to local update if online fails
    } catch (e) {
      debugPrint('Online image upload failed: $e');
    }

    // Fallback to local update with local path
    try {
      await _authService.updateProfileImageLocally(state.user!.id, imageFile.path);
      final updatedUser = state.user!.copyWith(profileImage: imageFile.path);
      state = state.copyWith(user: updatedUser, isUpdating: false);
      _ref.read(authStateProvider.notifier).updateUser(updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'فشل تحديث الصورة: $e',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ProfileNotifier(authService, ref);
});
