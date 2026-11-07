class AppConfig {
  static const String appName = 'ECOSYSTEM REWIND';
  static const String brandName = 'PRITHVI LABS';
  static const String appTagline = 'Understand the Domino. Restore the Future.';
  static const String appDescription =
      'Explore ecological relationships, identify potential ecosystem risks, and compare restoration strategies through data-driven analysis.';

  // Environment-configurable API Base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String apiPrefix = '/api';

  static String get fullApiUrl => '$apiBaseUrl$apiPrefix';
}
