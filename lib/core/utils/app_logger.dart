import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    debugPrint('[$timestamp] ERROR [$scope] ${_formatError(error)}');
    if (stackTrace != null) {
      debugPrintStack(
        label: '[$timestamp] STACK [$scope]',
        stackTrace: stackTrace,
      );
    }
  }

  static String _formatError(Object error) {
    if (error is PostgrestException) {
      return 'PostgrestException('
          'code=${error.code}, '
          'message=${error.message}, '
          'details=${error.details}, '
          'hint=${error.hint}'
          ')';
    }
    if (error is StorageException) {
      return 'StorageException('
          'statusCode=${error.statusCode}, '
          'message=${error.message}, '
          'error=${error.error}'
          ')';
    }
    if (error is AuthApiException) {
      return 'AuthApiException('
          'code=${error.code}, '
          'statusCode=${error.statusCode}, '
          'message=${error.message}'
          ')';
    }
    if (error is AuthRetryableFetchException) {
      return 'AuthRetryableFetchException('
          'statusCode=${error.statusCode}, '
          'message=${error.message}'
          ')';
    }
    if (error is AuthException) {
      return 'AuthException('
          'code=${error.code}, '
          'statusCode=${error.statusCode}, '
          'message=${error.message}'
          ')';
    }
    return error.toString();
  }
}
