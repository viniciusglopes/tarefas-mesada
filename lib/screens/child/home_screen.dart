import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/child_service.dart';
import '../../services/session_service.dart';
import 'cards_screen.dart';
import 'badges_screen.dart';
import 'shop_screen.dart';
import 'messages_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildHomeScreen({super.key, required this.childData});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  late Child _child;
  List<Task> _tasks = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _child = Child.fromJson(widget.childData);
    _loadTasks();
  }

  Future<void> _refreshChild() async {
    final updated = await ChildService.getChild(_child.id);
    setState(() => _child = updated);
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskService.getTasksForChild(_child.id);
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _completedCount => _tasks.where((t) => t.status != TaskStatus.pending).length;

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 1:
        return CardsScreen(child: _child);
      case 2:
        return BadgesScreen(child: _child);
      case 3:
        return ShopScreen(child: _child);
      case 4:
        return MessagesScreen(child: _child);
      default:
        return _buildHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) {
            _refreshChild();
            _loadTasks();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Cartas'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Insignias'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Loja'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Mensagens'),
        ],
      ),
    );
  }

  void _logout() async {
    await SessionService.clearChildSession();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }

  Widget _buildHome() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _refreshChild();
          await _loadTasks();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _child.avatarWidget(size: 30, fontSize: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_child.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.xpPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nivel ${_child.level}',
                              style: const TextStyle(fontSize: 12, color: AppColors.xpPurple, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (_child.streak > 0) ...[
                            const SizedBox(width: 8),
                            Text('🔥 ${_child.streak} dias', style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${_child.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.childGreen),
                    ),
                    Text('${_child.xp} XP', style: const TextStyle(fontSize: 12, color: AppColors.xpPurple)),
                    GestureDetector(
                      onTap: _logout,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XP para proximo nivel', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${_child.xp} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_child.xp % 100) / 100,
                    backgroundColor: AppColors.xpPurple.withValues(alpha: 0.1),
                    color: AppColors.xpPurple,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _StatCard(icon: '✅', value: '$_completedCount', label: 'Feitas'),
                const SizedBox(width: 10),
                _StatCard(icon: '🏅', value: '0', label: 'Insignias'),
                const SizedBox(width: 10),
                _StatCard(icon: '🃏', value: 'Nv${_child.level}', label: 'Carta'),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tarefas de Hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$_completedCount/${_tasks.length}',
                  style: const TextStyle(fontSize: 14, color: AppColors.childGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_tasks.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _tasks.isEmpty ? 0 : _completedCount / _tasks.length,
                  backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
                  color: AppColors.childGreen,
                  minHeight: 8,
                ),
              ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: const [
                      Text('🎉', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('Nenhuma tarefa para hoje!', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ..._tasks.map((task) => _TaskCard(
                task: task,
                onComplete: () async {
                  await TaskService.completeTask(task.id);
                  _loadTasks();
                },
              )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;

  const _TaskCard({required this.task, required this.onComplete});

  bool get _isDone => task.status != TaskStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isDone ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isDone ? AppColors.childGreen.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Text(task.template?.icon ?? '📋', style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.template?.title ?? 'Tarefa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: _isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${task.template?.xpReward ?? 0} XP • R\$ ${(task.template?.moneyReward ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!_isDone)
              SizedBox(
                width: 52,
                height: 52,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.childGreen,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(52, 52),
                  ),
                  child: const Icon(Icons.check, size: 28),
                ),
              )
            else
              const Icon(Icons.check_circle, color: AppColors.childGreen, size: 32),
          ],
        ),
      ),
    );
  }
}
