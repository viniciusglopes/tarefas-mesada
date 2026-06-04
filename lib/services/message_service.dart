import 'supabase_service.dart';
import '../models/message.dart';

class MessageService {
  static final _client = SupabaseService.client;

  static Future<List<Message>> getMessages({
    required String familyId,
    required String childId,
  }) async {
    final result = await _client
        .from('messages')
        .select()
        .eq('family_id', familyId)
        .or('sender_child_id.eq.$childId,receiver_child_id.eq.$childId')
        .order('created_at');

    return (result as List).map((e) => Message.fromJson(e)).toList();
  }

  static Future<void> sendFromChild({
    required String familyId,
    required String childId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'family_id': familyId,
      'sender_type': 'child',
      'sender_child_id': childId,
      'content': content,
    });
  }

  static Future<void> sendFromParent({
    required String familyId,
    required String parentId,
    required String receiverChildId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'family_id': familyId,
      'sender_type': 'parent',
      'sender_parent_id': parentId,
      'receiver_child_id': receiverChildId,
      'content': content,
    });
  }

  static Future<void> markAsRead(String messageId) async {
    await _client.from('messages').update({
      'is_read': true,
    }).eq('id', messageId);
  }

  static Future<void> markAsReadRpc(String messageId) async {
    await _client.rpc('mark_message_read', params: {'p_message_id': messageId});
  }

  static Future<List<Message>> getMessagesRpc({
    required String familyId,
    required String childId,
  }) async {
    final result = await _client.rpc('get_child_messages', params: {
      'p_family_id': familyId,
      'p_child_id': childId,
    });
    if (result == null) return [];
    return (result as List).map((e) => Message.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> sendFromChildRpc({
    required String familyId,
    required String childId,
    required String content,
  }) async {
    await _client.rpc('send_child_message', params: {
      'p_family_id': familyId,
      'p_child_id': childId,
      'p_content': content,
    });
  }

  static Future<int> getUnreadCount({
    required String familyId,
    required String childId,
  }) async {
    final result = await _client
        .from('messages')
        .select()
        .eq('family_id', familyId)
        .eq('receiver_child_id', childId)
        .eq('is_read', false);

    return (result as List).length;
  }
}
