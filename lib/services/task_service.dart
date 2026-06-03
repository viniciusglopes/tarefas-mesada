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

  static Future<List<TaskTemplate>> getTaskTemplates(String familyId) async {
    final result = await _client
        .from('task_templates')
        .select()
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('title');

    return (result as List).map((e) => TaskTemplate.fromJson(e)).toList();
  }

  static Future<void> updateTaskTemplate({
    required String templateId,
    required String title,
    String? description,
    String icon = '📋',
    int xpReward = 10,
    double moneyReward = 0,
    String frequency = 'daily',
    String? category,
    String? assignedTo,
  }) async {
    await _client.from('task_templates').update({
      'title': title,
      'description': description,
      'icon': icon,
      'xp_reward': xpReward,
      'money_reward': moneyReward,
      'frequency': frequency,
      'category': category,
      'assigned_to': assignedTo,
    }).eq('id', templateId);
  }

  static Future<void> deleteTaskTemplate(String templateId) async {
    await _client.from('task_templates').update({'is_active': false}).eq('id', templateId);
  }

  static Future<void> assignTaskToChild({
    required String templateId,
    required String childId,
    required String familyId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    await _client.from('tasks').insert({
      'template_id': templateId,
      'child_id': childId,
      'family_id': familyId,
      'date': targetDate.toIso8601String().split('T').first,
      'status': 'pending',
    });
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

  static const _defaultTasks = [
    {'icon': '🦷', 'title': 'Escovar os dentes apos as refeicoes', 'xp': 10, 'category': 'hygiene'},
    {'icon': '🛏️', 'title': 'Arrumar a cama', 'xp': 10, 'category': 'organization'},
    {'icon': '☕', 'title': 'Tomar cafe da manha', 'xp': 5, 'category': 'health'},
    {'icon': '📚', 'title': 'Fazer o dever de casa', 'xp': 20, 'category': 'study'},
    {'icon': '🍽️', 'title': 'Almocar', 'xp': 5, 'category': 'health'},
    {'icon': '🚿', 'title': 'Tomar banho', 'xp': 10, 'category': 'hygiene'},
    {'icon': '🧸', 'title': 'Arrumar os brinquedos', 'xp': 10, 'category': 'organization'},
    {'icon': '🧼', 'title': 'Lavar as maos antes de comer', 'xp': 5, 'category': 'hygiene'},
    {'icon': '💇', 'title': 'Pentear o cabelo', 'xp': 5, 'category': 'hygiene'},
    {'icon': '👕', 'title': 'Guardar a roupa suja no cesto', 'xp': 5, 'category': 'organization'},
    {'icon': '🍽️', 'title': 'Colocar o prato na pia apos comer', 'xp': 5, 'category': 'responsibility'},
    {'icon': '🎒', 'title': 'Guardar o material escolar na mochila', 'xp': 10, 'category': 'organization'},
    {'icon': '👔', 'title': 'Preparar a roupa do dia seguinte', 'xp': 10, 'category': 'organization'},
    {'icon': '🐾', 'title': 'Dar comida/agua pro pet', 'xp': 10, 'category': 'responsibility'},
    {'icon': '📖', 'title': 'Ler por 15 minutos', 'xp': 15, 'category': 'study'},
    {'icon': '🎹', 'title': 'Praticar instrumento ou atividade extra', 'xp': 15, 'category': 'study'},
    {'icon': '🍴', 'title': 'Ajudar a por ou tirar a mesa', 'xp': 10, 'category': 'social'},
    {'icon': '🙏', 'title': 'Dizer obrigado e por favor', 'xp': 5, 'category': 'social'},
  ];

  static Future<void> createDefaultTasks({required String familyId}) async {
    final existing = await getTaskTemplates(familyId);
    if (existing.isNotEmpty) return;

    for (final task in _defaultTasks) {
      await _client.from('task_templates').insert({
        'family_id': familyId,
        'title': task['title'],
        'icon': task['icon'],
        'xp_reward': task['xp'],
        'money_reward': 0,
        'frequency': 'daily',
        'category': task['category'],
      });
    }
  }
}
