import 'supabase_service.dart';
import '../models/task.dart';

class TaskService {
  static final _client = SupabaseService.client;

  static Future<List<Task>> getTasksForChild(String childId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T').first;

    final result = await _client
        .from('tasks')
        .select('*, task_templates(*)')
        .eq('child_id', childId)
        .eq('date', dateStr)
        .order('created_at');

    return (result as List).map((e) => Task.fromJson(e)).toList();
  }

  static Future<List<Task>> getPendingApprovals(String familyId) async {
    final result = await _client
        .from('tasks')
        .select('*, task_templates(*)')
        .eq('family_id', familyId)
        .eq('status', 'completed')
        .order('completed_at');

    return (result as List).map((e) => Task.fromJson(e)).toList();
  }

  static Future<void> completeTask(String taskId) async {
    await _client.from('tasks').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  static Future<void> approveTask(String taskId, String parentId) async {
    final task = await _client
        .from('tasks')
        .select('*, task_templates(*)')
        .eq('id', taskId)
        .single();

    await _client.from('tasks').update({
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
      'approved_by': parentId,
    }).eq('id', taskId);

    final xp = task['task_templates']['xp_reward'] ?? 0;
    final money = (task['task_templates']['money_reward'] ?? 0).toDouble();
    final childId = task['child_id'];

    if (xp > 0 || money > 0) {
      await _client.rpc('increment_child_rewards', params: {
        'p_child_id': childId,
        'p_xp': xp,
        'p_money': money,
      });
    }
  }

  static Future<void> rejectTask(String taskId) async {
    await _client.from('tasks').update({
      'status': 'rejected',
    }).eq('id', taskId);
  }

  static Future<void> createTaskTemplate({
    required String familyId,
    required String title,
    String? description,
    String icon = '📋',
    int xpReward = 10,
    double moneyReward = 0,
    String frequency = 'daily',
    String? category,
    String? assignedTo,
  }) async {
    await _client.from('task_templates').insert({
      'family_id': familyId,
      'title': title,
      'description': description,
      'icon': icon,
      'xp_reward': xpReward,
      'money_reward': moneyReward,
      'frequency': frequency,
      'category': category,
      'assigned_to': assignedTo,
    });
  }
}
