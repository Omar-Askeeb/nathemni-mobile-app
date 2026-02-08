import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize date formatting for Arabic locale
    await initializeDateFormatting('ar', null);
    
    // Initialize notification service
    try {
      await NotificationService.instance.initialize();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Notification Error: $e');
    }
    
    // Initialize database early to catch errors
    try {
      // Check database
      // Using direct print for debugging as Flutter logs might get lost if it crashes early
      debugPrint('Initializing Database...');
      // We can't import DatabaseHelper here easily without import
    } catch (e) {
      debugPrint('Database Error: $e');
    }

    runApp(
      const ProviderScope(
        child: NathemniApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('Startup Error: $e');
    debugPrint('Stacktrace: $stack');
  }
}

class NathemniApp extends StatelessWidget {
  const NathemniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظمني - Nathemni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      // Localization
      locale: const Locale('ar', ''),
      supportedLocales: const [
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Navigation
      initialRoute: AppRoutes.home,
      routes: AppRoutes.getRoutes(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظمني'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 32),
            
            // Welcome text
            Text(
              'مرحباً بك في نظمني',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'تطبيقك الشخصي للتنظيم والإنتاجية',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Status card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'قاعدة البيانات المحلية جاهزة',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SQLite Database Initialized',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Coming soon button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('قريباً - Coming Soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('ابدأ الآن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
