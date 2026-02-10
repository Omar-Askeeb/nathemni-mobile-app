import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// Profile screen to display user information
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile on init
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Navigate to login immediately, then logout in background
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      // Perform logout after navigation
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  Widget _buildProfileImage(String? profileImage) {
    Widget imageWidget;

    if (profileImage != null && profileImage.isNotEmpty) {
      if (profileImage.startsWith('http')) {
        // Network image
        imageWidget = CachedNetworkImage(
          imageUrl: profileImage,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            size: 60,
            color: Colors.white70,
          ),
        );
      } else {
        // Local file
        imageWidget = Image.file(
          File(profileImage),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person,
            size: 60,
            color: Colors.white70,
          ),
        );
      }
    } else {
      imageWidget = const Icon(
        Icons.person,
        size: 60,
        color: Colors.white70,
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? '-',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: label.contains('English') || label.contains('email') || label.contains('username')
                      ? TextDirection.ltr
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
            tooltip: 'تعديل',
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لم يتم العثور على بيانات المستخدم',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Image
                      _buildProfileImage(user.profileImage),
                      const SizedBox(height: 16),

                      // Display Name
                      Text(
                        user.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.username != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.person,
                        label: 'الاسم بالعربية',
                        value: user.nameAr,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Name in English',
                        value: user.nameEn,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.alternate_email,
                        label: 'اسم المستخدم (username)',
                        value: user.username,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.phone,
                        label: 'رقم الهاتف',
                        value: user.phone,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.email,
                        label: 'البريد الإلكتروني (email)',
                        value: user.email,
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('تسجيل الخروج'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
