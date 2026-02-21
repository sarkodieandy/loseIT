import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] INFO $message');
  }

  static void warn(String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] WARN $message');
  }

  static void error(
    String scope,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] ERROR [$scope] $error');
    if (stackTrace != null) {
      debugPrintStack(
        label: '[$timestamp] STACK [$scope]',
        stackTrace: stackTrace,
      );
    }
  }
}
