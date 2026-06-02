import 'supabase_service.dart';
import 'auth_service.dart';
import '../models/child.dart';

class ChildService {
  static final _client = SupabaseService.client;

  static Future<List<Child>> getChildren(String familyId) async {
    final result = await _client
        .from('children')
        .select()
        .eq('family_id', familyId)
        .order('name');

    return (result as List).map((e) => Child.fromJson(e)).toList();
  }

  static Future<Child> getChild(String childId) async {
    final result = await _client
        .from('children')
        .select()
        .eq('id', childId)
        .single();

    return Child.fromJson(result);
  }

  static Future<void> createChild({
    required String familyId,
    required String name,
    required String username,
    required String pin,
    String? gender,
    DateTime? birthDate,
    String? avatarUrl,
    String avatarType = 'emoji',
  }) async {
    await _client.rpc('create_child', params: {
      'p_family_id': familyId,
      'p_name': name,
      'p_username': username,
      'p_pin_hash': AuthService.hashPin(pin),
      'p_gender': gender,
      'p_birth_date': birthDate?.toIso8601String().split('T').first,
      'p_avatar_url': avatarUrl,
      'p_avatar_type': avatarType,
    });
  }

  static Future<void> updateChild({
    required String childId,
    String? name,
    String? avatarUrl,
    String? avatarType,
    String? gender,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (avatarType != null) updates['avatar_type'] = avatarType;
    if (gender != null) updates['gender'] = gender;

    await _client.from('children').update(updates).eq('id', childId);
  }

  static Future<void> updatePin({
    required String childId,
    required String newPin,
  }) async {
    await _client.from('children').update({
      'pin_hash': AuthService.hashPin(newPin),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', childId);
  }

  static Future<Map<String, dynamic>> getPermissions(String childId) async {
    final result = await _client
        .from('child_permissions')
        .select()
        .eq('child_id', childId)
        .maybeSingle();

    return result ?? {
      'can_see_balance': true,
      'can_see_xp': true,
      'can_mark_tasks': true,
      'can_see_cards': true,
      'can_see_ranking': true,
      'can_use_shop': true,
      'can_send_messages': true,
    };
  }

  static Future<void> updatePermissions({
    required String childId,
    required Map<String, bool> permissions,
  }) async {
    final data = {
      'child_id': childId,
      ...permissions,
    };

    await _client.from('child_permissions').upsert(data);
  }
}
