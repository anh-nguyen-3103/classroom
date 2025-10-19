import 'dart:developer' as developer;

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  /// Log a debug message
  void debug(String message) {
    developer.log('🐛 $message', name: 'DEBUG');
  }

  /// Log an info message
  void info(String message) {
    developer.log('ℹ️ $message', name: 'INFO');
  }

  /// Log a warning message
  void warning(String message) {
    developer.log('⚠️ $message', name: 'WARNING');
  }

  /// Log an error message
  void error(String message, [dynamic exception, StackTrace? stackTrace]) {
    developer.log(
      '❌ $message',
      name: 'ERROR',
      error: exception,
      stackTrace: stackTrace,
    );
  }
}
