import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/home_screen.dart';

/// Wrapper widget that handles authentication state and routing
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status when the widget initializes
    Future.microtask(() {
      ref.read(authStateProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return switch (authState) {
      AuthInitial() || AuthLoading() => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/paddin_logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 32),
                SpinKitFadingCircle(
                  color: theme.colorScheme.primary,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'جاري التحميل...',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      AuthAuthenticated() => const HomeScreen(),
      AuthUnauthenticated(needsRegistration: true) => const RegisterScreen(),
      AuthUnauthenticated(needsRegistration: false) => const LoginScreen(),
      AuthError(:final message) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).checkAuthStatus();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
    };
  }
}
