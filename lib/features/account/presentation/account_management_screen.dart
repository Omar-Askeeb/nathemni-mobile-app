import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../../../core/navigation/app_routes.dart';

/// Account management screen for user settings
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحساب'),
      ),
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Header
                  _buildUserInfoCard(user.displayName, user.email, theme),
                  const SizedBox(height: 24),

                  // Profile Section
                  _buildSectionHeader('الملف الشخصي', Icons.person, theme),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.edit,
                    title: 'تعديل بيانات المستخدم',
                    subtitle: 'تعديل الاسم والبريد الإلكتروني ورقم الهاتف',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                    trailing: const Icon(Icons.chevron_left, size: 20),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    icon: Icons.badge_outlined,
                    title: 'عرض الملف الشخصي',
                    subtitle: 'عرض جميع بياناتك الشخصية',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                    trailing: const Icon(Icons.chevron_left, size: 20),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // Security Section
                  _buildSectionHeader('الأمان', Icons.security, theme),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.lock_outline,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث كلمة المرور الخاصة بك',
                    onTap: () => _showChangePasswordDialog(context),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // Data Management Section
                  _buildSectionHeader('إدارة البيانات', Icons.storage, theme),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.download,
                    title: 'تصدير البيانات',
                    subtitle: 'تصدير جميع بياناتك',
                    onTap: () => _showExportDataDialog(context),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    icon: Icons.cleaning_services,
                    title: 'مسح البيانات المؤقتة',
                    subtitle: 'تنظيف ذاكرة التخزين المؤقت',
                    onTap: () => _showClearCacheDialog(context),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // App Settings Section
                  _buildSectionHeader('إعدادات التطبيق', Icons.settings, theme),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.language,
                    title: 'اللغة',
                    subtitle: 'العربية',
                    onTap: () => _showLanguageDialog(context),
                    trailing: const Icon(Icons.chevron_left, size: 20),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات',
                    subtitle: 'إدارة إعدادات الإشعارات',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    trailing: const Icon(Icons.chevron_left, size: 20),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // Session Section
                  _buildSectionHeader('الجلسة', Icons.login, theme),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    subtitle: 'الخروج من حسابك الحالي',
                    onTap: () => _showLogoutDialog(context),
                    theme: theme,
                  ),
                  const SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionHeader('منطقة الخطر', Icons.warning_amber, theme, isWarning: true),
                  const SizedBox(height: 12),
                  _buildDangerCard(
                    icon: Icons.delete_forever,
                    title: 'حذف الحساب',
                    subtitle: 'حذف حسابك وجميع بياناتك نهائياً',
                    onTap: () => _showDeleteAccountDialog(context),
                    isLoading: _isDeleting,
                    theme: theme,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard(String name, String? email, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme, {bool isWarning = false}) {
    final color = isWarning ? theme.colorScheme.error : theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isLoading,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.error,
                  ),
                )
              : Icon(icon, color: theme.colorScheme.error),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.colorScheme.error.withValues(alpha: 0.7)),
        ),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthTextField(
                    label: 'كلمة المرور الحالية',
                    hint: '••••••••',
                    controller: currentPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      return null;
                    },
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'كلمة المرور الجديدة',
                    hint: '••••••••',
                    controller: newPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'تأكيد كلمة المرور الجديدة',
                    hint: '••••••••',
                    controller: confirmPasswordController,
                    obscureText: true,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      if (v != newPasswordController.text) return 'كلمات المرور غير متطابقة';
                      return null;
                    },
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      final success = await ref.read(authStateProvider.notifier).changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                      setDialogState(() => isLoading = false);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'تم تغيير كلمة المرور بنجاح'
                                : 'فشل تغيير كلمة المرور - تأكد من كلمة المرور الحالية'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('حذف الحساب'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف حسابك؟'),
            SizedBox(height: 12),
            Text(
              'سيتم حذف جميع بياناتك نهائياً ولا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() => _isDeleting = true);

              final success = await ref.read(authStateProvider.notifier).deleteAccount();

              setState(() => _isDeleting = false);

              if (context.mounted) {
                if (success) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.wrapper,
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل حذف الحساب'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('هذه الميزة قيد التطوير وستكون متاحة قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح البيانات المؤقتة'),
        content: const Text('سيتم مسح جميع البيانات المؤقتة. لن يؤثر هذا على بياناتك المحفوظة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح البيانات المؤقتة'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: Colors.green),
              title: const Text('العربية'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('English'),
              subtitle: const Text('قريباً', style: TextStyle(fontSize: 12)),
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);  // Close dialog
              // Navigate to login immediately, then logout in background
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
              // Perform logout after navigation
              await ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
