import 'package:supabase_flutter/supabase_flutter.dart';

String supabaseErrorText(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  if (error is PostgrestException) {
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }
  final text = error.toString().trim();
  final lower = text.toLowerCase();
  if (lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('clientexception')) {
    return 'Network unavailable. Check your internet connection and try again.';
  }
  if (lower.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }
  if (text.isEmpty) return 'Something went wrong. Please try again.';
  return text;
}
