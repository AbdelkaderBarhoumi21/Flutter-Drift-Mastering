class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.yourbackend.com';
  static const String apiVersion = '/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Pagination
  static const int defaultPageSize = 20;

  // Database
  static const String databaseName = 'drift_sync_app.db';
  static const int databaseVersion = 1;
}

class ApiEndpoints {
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String sync = '/sync';
  static const String conflicts = '/conflicts';
}
