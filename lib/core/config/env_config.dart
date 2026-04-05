/// Environment configuration for API endpoints
class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://nathemni.ly/api/v1';
      case 'staging':
        return 'https://staging.nathemni.ly/api/v1';
      case 'dev':
      default:
        // For development on physical device, use your local network IP
        // Example: return 'http://192.168.1.100:8000/api/v1';
        return 'https://nathemni.ly/api/v1';
    }
  }

  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Debug mode
  static const bool isDevelopment = environment == 'dev';
  static const bool isProduction = environment == 'prod';
}
