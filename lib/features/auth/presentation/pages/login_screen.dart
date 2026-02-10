import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../../../../core/navigation/app_routes.dart';

/// Login screen for existing users
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Navigate to auth wrapper which will redirect to home
      Navigator.pushReplacementNamed(context, AppRoutes.wrapper);
    }
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني أو رقم الهاتف مطلوب';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
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
                const SizedBox(height: 60),
                
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/paddin_logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'مرحباً بعودتك',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل دخولك للمتابعة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Identifier (Email or Phone)
                AuthTextField(
                  label: 'البريد الإلكتروني أو رقم الهاتف',
                  hint: 'example@email.com أو 09XXXXXXXX',
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: _validateIdentifier,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 20),

                // Password
                AuthTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !isLoading,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AuthTextButton(
                    text: 'نسيت كلمة المرور؟',
                    onPressed: isLoading
                        ? null
                        : () {
                            // TODO: Implement forgot password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('قريباً - Coming Soon'),
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                AuthButton(
                  text: 'تسجيل الدخول',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                  icon: Icons.login,
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: theme.textTheme.bodyMedium,
                    ),
                    AuthTextButton(
                      text: 'إنشاء حساب',
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.register,
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
