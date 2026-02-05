import 'package:logger/logger.dart';

class AppLogger {
  factory AppLogger() => _instance;
  AppLogger._internal();
  static final AppLogger _instance = AppLogger._internal();
  // Create a Logger instance
  final Logger _logger = Logger(
    filter: ProductionFilter(), // You can customize filters based on your needs
    printer: PrettyPrinter(methodCount: 3), // Customize how logs are printed
    output: ConsoleOutput(), // Logs will output to the console
  );

  // Singleton pattern to ensure there's only one instance of AppLogger

  // Log a message at Debug level
  void d(String message) {
    _logger.d(message);
  }

  // Log a message at Info level (equivalent to 'info' in SyncEngine)
  void info(String message) {
    _logger.i(message);
  }

  // Log a message at Warn level (equivalent to 'warn' in SyncEngine)
  void warn(String message) {
    _logger.w(message);
  }

  // Log a message at Error level (equivalent to 'error' in SyncEngine)
  void error(String message, dynamic error) {
    _logger.e(message, error: error);
  }

  // Log a message at Trace level
  void t(String message) {
    _logger.t(message);
  }

  // Log a message at Fatal level
  void f(String message) {
    _logger.f(message);
  }

  // Log an exception or error
  void logError(dynamic error, StackTrace stackTrace) {
    _logger.e(error, stackTrace: stackTrace);
  }
}
