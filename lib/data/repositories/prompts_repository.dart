import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/daily_prompt.dart';

class PromptsRepository {
  PromptsRepository(this._client);

  final SupabaseClient _client;

  Future<List<DailyPrompt>> fetchPrompts({bool includePremium = false}) async {
    try {
      final query = _client.from('daily_prompts').select();
      final rows = includePremium
          ? await query
          : await query.eq('is_premium', false);
      return (rows as List<dynamic>)
          .map((row) => DailyPrompt.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('prompts.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('prompts.fetch', error, stackTrace);
      rethrow;
    }
  }
}
