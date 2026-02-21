import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../subscription_repository.dart';
import 'profile_store.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final SupabaseProfileStore _profiles;

  @override
  Future<bool> isPremium() => _profiles.isPremium();

  @override
  Future<void> setPremium(bool value) => _profiles.setPremium(value);

  @override
  Future<SubscriptionVerificationResult> verifyAppleSubscription({
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    final payload = <String, dynamic>{
      'productId': productId.trim(),
      'verificationData': verificationData.trim(),
      if (transactionId != null && transactionId.trim().isNotEmpty)
        'transactionId': transactionId.trim(),
    };

    final response = await _client.functions.invoke(
      'verify-ios-subscription',
      body: payload,
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final message = _readString(data, 'error') ??
          _readString(data, 'message') ??
          'Unable to verify subscription with server.';
      throw AuthException(message);
    }

    if (data is! Map) {
      throw const AuthException(
        'Invalid verification response from server.',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final isPremium = _toBool(map['isPremium'], fallback: false);
    final status = _readString(map, 'status') ?? 'inactive';
    final expiresAt = _toDateTime(map['expiresAt']);
    final message = _readString(map, 'message');

    try {
      await _profiles.setPremium(isPremium);
    } catch (error, stackTrace) {
      AppLogger.error(
        'SupabaseSubscriptionRepository.verifyAppleSubscription.setPremium',
        error,
        stackTrace,
      );
    }

    return SubscriptionVerificationResult(
      isPremium: isPremium,
      status: status,
      expiresAt: expiresAt,
      message: message,
    );
  }

  String? _readString(dynamic source, String key) {
    if (source is! Map) return null;
    final value = source[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}
