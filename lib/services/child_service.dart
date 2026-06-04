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

  static Future<bool> isUsernameTaken(String username, {String? excludeChildId}) async {
    var query = _client.from('children').select('id').eq('username', username.toLowerCase());
    if (excludeChildId != null) {
      query = query.neq('id', excludeChildId);
    }
    final result = await query;
    return (result as List).isNotEmpty;
  }

  static Future<void> updateChild({
    required String childId,
    String? name,
    String? username,
    String? avatarUrl,
    String? avatarType,
    String? gender,
    double? allowanceAmount,
    String? allowanceFrequency,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (username != null) updates['username'] = username.toLowerCase();
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (avatarType != null) updates['avatar_type'] = avatarType;
    if (gender != null) updates['gender'] = gender;
    if (allowanceAmount != null) updates['allowance_amount'] = allowanceAmount;
    if (allowanceFrequency != null) updates['allowance_frequency'] = allowanceFrequency;

    await _client.from('children').update(updates).eq('id', childId);
  }

  static Future<void> deleteChild(String childId) async {
    await _client.from('children').delete().eq('id', childId);
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

  static Future<void> resetPeriod({
    required String childId,
    required String familyId,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
    required double allowanceAmount,
  }) async {
    final child = await getChild(childId);

    final tasksResult = await _client
        .from('tasks')
        .select()
        .eq('child_id', childId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    final tasks = tasksResult as List;
    final completed = tasks.where((t) => t['status'] == 'approved').length;
    final moneyEarned = tasks.fold<double>(0, (sum, t) {
      if (t['status'] == 'approved' && t['task_templates'] != null) {
        return sum + ((t['task_templates']['money_reward'] ?? 0) as num).toDouble();
      }
      return sum;
    });

    final penaltiesResult = await _client
        .from('penalties')
        .select()
        .eq('child_id', childId)
        .gte('applied_at', startDate.toIso8601String())
        .lte('applied_at', endDate.toIso8601String());

    final penalties = penaltiesResult as List;
    final moneyLost = penalties.fold<double>(0, (sum, p) => sum + ((p['money_lost'] ?? 0) as num).toDouble());

    await _client.from('allowance_periods').insert({
      'child_id': childId,
      'family_id': familyId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'frequency': frequency,
      'allowance_amount': allowanceAmount,
      'tasks_completed': completed,
      'tasks_total': tasks.length,
      'money_earned': moneyEarned,
      'penalties_applied': penalties.length,
      'money_lost': moneyLost,
      'final_balance': child.balance,
      'status': 'closed',
      'closed_by': SupabaseService.currentUser?.id,
    });

    await _client.from('children').update({
      'period_start_date': DateTime.now().toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', childId);
  }

  static Future<List<Map<String, dynamic>>> getPeriodHistory(String childId) async {
    final result = await _client
        .from('allowance_periods')
        .select()
        .eq('child_id', childId)
        .order('end_date', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(result);
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
