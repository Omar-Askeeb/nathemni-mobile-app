import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../../../../core/navigation/app_routes.dart';

/// Registration screen for new users
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).register(
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Show success message and navigate to auth wrapper (auto-logged in)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التسجيل بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.wrapper);
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (value.trim().length < 9) {
      return 'رقم الهاتف غير صالح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != _passwordController.text) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.trim().length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    // Listen for errors
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/paddin_logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'إنشاء حساب جديد',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل بياناتك لإنشاء حسابك في نظمني',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Arabic Name
                AuthTextField(
                  label: 'الاسم بالعربية',
                  hint: 'أدخل اسمك بالعربية',
                  controller: _nameArController,
                  enabled: !isLoading,
                  validator: (v) => _validateRequired(v, 'الاسم بالعربية'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // English Name
                AuthTextField(
                  label: 'الاسم بالإنجليزية',
                  hint: 'Enter your name in English',
                  controller: _nameEnController,
                  enabled: !isLoading,
                  validator: (v) => _validateRequired(v, 'الاسم بالإنجليزية'),
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 16),

                // Username
                AuthTextField(
                  label: 'اسم المستخدم (النك نيم)',
                  hint: 'username',
                  controller: _usernameController,
                  enabled: !isLoading,
                  validator: _validateUsername,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                const SizedBox(height: 16),

                // Phone
                PhoneInputField(
                  controller: _phoneController,
                  enabled: !isLoading,
                  validator: _validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                AuthTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // Password
                AuthTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !isLoading,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                AuthTextField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  enabled: !isLoading,
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 32),

                // Register Button
                AuthButton(
                  text: 'إنشاء حساب',
                  onPressed: _handleRegister,
                  isLoading: isLoading,
                  icon: Icons.person_add,
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟',
                      style: theme.textTheme.bodyMedium,
                    ),
                    AuthTextButton(
                      text: 'تسجيل الدخول',
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
