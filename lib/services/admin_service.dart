import 'supabase_service.dart';

class AdminService {
  static final _client = SupabaseService.client;

  static const adminEmails = ['viniciusglopes@gmail.com'];

  static bool isAdmin() {
    final email = SupabaseService.currentUser?.email;
    return email != null && adminEmails.contains(email);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final families = await _client.from('families').select('id');
    final parents = await _client.from('parents').select('id');
    final children = await _client.from('children').select('id, xp, balance, level, streak');

    final today = DateTime.now().toIso8601String().split('T').first;
    final tasksToday = await _client
        .from('tasks')
        .select('id')
        .eq('date', today);

    final tasksCompleted = await _client
        .from('tasks')
        .select('id')
        .eq('status', 'approved');

    final tasksPending = await _client
        .from('tasks')
        .select('id')
        .eq('status', 'completed');

    final childList = children as List;
    final totalBalance = childList.fold<double>(0, (sum, c) => sum + ((c['balance'] ?? 0) as num).toDouble());
    final totalXp = childList.fold<int>(0, (sum, c) => sum + ((c['xp'] ?? 0) as int));
    final avgLevel = childList.isEmpty ? 0.0 : childList.fold<double>(0, (sum, c) => sum + ((c['level'] ?? 1) as int)) / childList.length;
    final maxStreak = childList.isEmpty ? 0 : childList.fold<int>(0, (max, c) {
      final s = (c['streak'] ?? 0) as int;
      return s > max ? s : max;
    });

    return {
      'total_families': (families as List).length,
      'total_parents': (parents as List).length,
      'total_children': childList.length,
      'tasks_today': (tasksToday as List).length,
      'tasks_approved': (tasksCompleted as List).length,
      'tasks_pending_approval': (tasksPending as List).length,
      'total_balance': totalBalance,
      'total_xp': totalXp,
      'avg_level': avgLevel,
      'max_streak': maxStreak,
    };
  }

  static Future<List<Map<String, dynamic>>> getFamilies() async {
    final result = await _client
        .from('families')
        .select('id, name, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getParents() async {
    final result = await _client
        .from('parents')
        .select('id, name, email, family_id, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getChildren() async {
    final result = await _client
        .from('children')
        .select('id, name, username, family_id, xp, level, balance, streak, best_streak, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<List<Map<String, dynamic>>> getRecentTasks({int limit = 50}) async {
    final result = await _client
        .from('tasks')
        .select('id, child_id, status, date, completed_at, approved_at, task_templates(title, icon, xp_reward, money_reward)')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<Map<String, dynamic>> getFamilyDetail(String familyId) async {
    final family = await _client
        .from('families')
        .select()
        .eq('id', familyId)
        .single();

    final parents = await _client
        .from('parents')
        .select()
        .eq('family_id', familyId);

    final children = await _client
        .from('children')
        .select()
        .eq('family_id', familyId);

    final tasks = await _client
        .from('tasks')
        .select('*, task_templates(*)')
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .limit(20);

    return {
      'family': family,
      'parents': parents,
      'children': children,
      'recent_tasks': tasks,
    };
  }
}
