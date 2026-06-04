import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/supabase_service.dart';

class ChildTasksScreen extends StatefulWidget {
  final Child child;
  const ChildTasksScreen({super.key, required this.child});

  @override
  State<ChildTasksScreen> createState() => _ChildTasksScreenState();
}

class _ChildTasksScreenState extends State<ChildTasksScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
  }

  int get _completedCount => _tasks.where((t) => t.status != TaskStatus.pending).length;

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskService.getTasksForChild(widget.child.id, date: _selectedDate);
      setState(() { _tasks = tasks; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markCompleted(Task task) async {
    await TaskService.completeTask(task.id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.template?.title ?? "Tarefa"} marcada como feita'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _approve(Task task) async {
    await TaskService.approveTask(task.id, SupabaseService.currentUser!.id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.template?.title ?? "Tarefa"} aprovada! +${task.template?.xpReward ?? 0} XP'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _reject(Task task) async {
    await TaskService.rejectTask(task.id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.template?.title ?? "Tarefa"} rejeitada'), backgroundColor: AppColors.warning),
      );
    }
  }

  Future<void> _delete(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir tarefa?'),
        content: Text('Remover "${task.template?.title ?? "Tarefa"}" deste dia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await TaskService.deleteTask(task.id);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa removida'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefas de ${widget.child.name}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); _loading = true; });
                    _loadTasks();
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() { _selectedDate = picked; _loading = true; });
                        _loadTasks();
                      }
                    },
                    child: Text(
                      _isToday
                          ? 'Hoje'
                          : '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() { _selectedDate = _selectedDate.add(const Duration(days: 1)); _loading = true; });
                    _loadTasks();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('$_completedCount/${_tasks.length} concluidas', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                if (!_isToday)
                  GestureDetector(
                    onTap: () {
                      setState(() { _selectedDate = DateTime.now(); _loading = true; });
                      _loadTasks();
                    },
                    child: const Text('Ir para hoje', style: TextStyle(fontSize: 13, color: AppColors.parentBlue, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          if (_tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _tasks.isEmpty ? 0 : _completedCount / _tasks.length,
                  backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
                  color: AppColors.childGreen,
                  minHeight: 6,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const Center(child: Text('Nenhuma tarefa neste dia', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return _ParentTaskCard(
                            task: task,
                            onComplete: () => _markCompleted(task),
                            onApprove: () => _approve(task),
                            onReject: () => _reject(task),
                            onDelete: () => _delete(task),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ParentTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _ParentTaskCard({
    required this.task,
    required this.onComplete,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.pending: return AppColors.textSecondary;
      case TaskStatus.completed: return AppColors.warning;
      case TaskStatus.approved: return AppColors.success;
      case TaskStatus.rejected: return AppColors.danger;
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.pending: return 'Pendente';
      case TaskStatus.completed: return 'Aguardando aprovacao';
      case TaskStatus.approved: return 'Aprovada';
      case TaskStatus.rejected: return 'Rejeitada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(task.template?.icon ?? '📋', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.template?.title ?? 'Tarefa', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_statusLabel, style: TextStyle(fontSize: 10, color: _statusColor, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${task.template?.xpReward ?? 0} XP',
                          style: const TextStyle(fontSize: 11, color: AppColors.xpPurple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                onPressed: onDelete,
                tooltip: 'Excluir',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (task.status == TaskStatus.pending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Marcar como feita'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.childGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          if (task.status == TaskStatus.completed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
