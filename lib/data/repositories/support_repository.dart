import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/support_connection.dart';
import '../models/support_message.dart';

class SupportRepository {
  SupportRepository(this._client);

  final SupabaseClient _client;

  Future<List<SupportConnection>> fetchConnections() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <SupportConnection>[];
    try {
      final rows = await _client
          .from('support_connections')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true) as List<dynamic>;
      return rows
          .map((row) => SupportConnection.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('support.fetchConnections', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('support.fetchConnections', error, stackTrace);
      rethrow;
    }
  }

  Future<SupportConnection> createConnection({
    required String contactName,
    String? phone,
    String? email,
    String? relationship,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    final payload = <String, dynamic>{
      'user_id': user.id,
      'contact_name': contactName,
      'contact_phone': phone,
      'contact_email': email,
      'relationship': relationship,
    };
    final row = await _client
        .from('support_connections')
        .insert(payload)
        .select()
        .single();
    return SupportConnection.fromJson(Map<String, dynamic>.from(row));
  }

  Stream<List<SupportMessage>> streamMessages(String connectionId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('connection_id', connectionId)
        .order('created_at')
        .map((rows) => rows
            .map((row) => SupportMessage.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList(growable: false));
  }

  Future<SupportMessage> sendMessage({
    required String connectionId,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    final payload = <String, dynamic>{
      'connection_id': connectionId,
      'sender_id': user.id,
      'message': message,
    };
    final row = await _client
        .from('support_messages')
        .insert(payload)
        .select()
        .single();
    return SupportMessage.fromJson(Map<String, dynamic>.from(row));
  }
}
