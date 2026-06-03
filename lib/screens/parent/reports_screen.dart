import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../services/supabase_service.dart';

class ReportsScreen extends StatefulWidget {
  final String familyId;
  final List<Child> children;
  const ReportsScreen({super.key, required this.familyId, required this.children});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic> _stats = {};
  Map<String, Map<String, dynamic>> _childStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = SupabaseService.client;
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final weekAgoStr = weekAgo.toIso8601String().split('T').first;
    final todayStr = today.toIso8601String().split('T').first;

    final allTasks = await client
        .from('tasks')
        .select('*, task_templates(*)')
        .eq('family_id', widget.familyId)
        .gte('date', weekAgoStr)
        .lte('date', todayStr);

    final taskList = allTasks as List;
    final approved = taskList.where((t) => t['status'] == 'approved').length;
    final rejected = taskList.where((t) => t['status'] == 'rejected').length;
    final pending = taskList.where((t) => t['status'] == 'completed').length;
    final notDone = taskList.where((t) => t['status'] == 'pending').length;

    final penalties = await client
        .from('penalties')
        .select()
        .eq('child_id', widget.children.isNotEmpty ? widget.children.first.id : '')
        .gte('applied_at', weekAgo.toIso8601String());

    final redemptions = await client
        .from('redemptions')
        .select('*, rewards(*)')
        .gte('redeemed_at', weekAgo.toIso8601String());

    final childStatsMap = <String, Map<String, dynamic>>{};
    for (final child in widget.children) {
      final childTasks = taskList.where((t) => t['child_id'] == child.id).toList();
      final childApproved = childTasks.where((t) => t['status'] == 'approved').length;
      final childTotal = childTasks.length;
      childStatsMap[child.id] = {
        'approved': childApproved,
        'total': childTotal,
        'percent': childTotal > 0 ? (childApproved * 100 / childTotal).round() : 0,
      };
    }

    setState(() {
      _stats = {
        'total_tasks': taskList.length,
        'approved': approved,
        'rejected': rejected,
        'pending': pending,
        'not_done': notDone,
        'penalties': (penalties as List).length,
        'redemptions': (redemptions as List).length,
      };
      _childStats = childStatsMap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatorios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Ultimos 7 dias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _StatCard(value: '${_stats['total_tasks'] ?? 0}', label: 'Tarefas', icon: '📋', color: AppColors.parentBlue),
                      const SizedBox(width: 10),
                      _StatCard(value: '${_stats['approved'] ?? 0}', label: 'Aprovadas', icon: '✅', color: AppColors.success),
                      const SizedBox(width: 10),
                      _StatCard(value: '${_stats['pending'] ?? 0}', label: 'Pendentes', icon: '⏳', color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatCard(value: '${_stats['rejected'] ?? 0}', label: 'Rejeitadas', icon: '❌', color: AppColors.danger),
                      const SizedBox(width: 10),
                      _StatCard(value: '${_stats['penalties'] ?? 0}', label: 'Penalidades', icon: '⚠️', color: Colors.orange),
                      const SizedBox(width: 10),
                      _StatCard(value: '${_stats['redemptions'] ?? 0}', label: 'Resgates', icon: '🎁', color: AppColors.xpPurple),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Desempenho por Filho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...widget.children.map((child) {
                    final stats = _childStats[child.id] ?? {'approved': 0, 'total': 0, 'percent': 0};
                    final percent = stats['percent'] as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
                                child: Text(child.avatarUrl ?? '🧒', style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '${stats['approved']}/${stats['total']} tarefas • Nivel ${child.level} • 🔥 ${child.streak}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: percent >= 80 ? AppColors.success : percent >= 50 ? AppColors.warning : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              backgroundColor: AppColors.border,
                              color: percent >= 80 ? AppColors.success : percent >= 50 ? AppColors.warning : AppColors.danger,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  const Text('Ranking Semanal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...List.generate(widget.children.length, (i) {
                    final sorted = [...widget.children]..sort((a, b) {
                      final aP = (_childStats[a.id]?['percent'] ?? 0) as int;
                      final bP = (_childStats[b.id]?['percent'] ?? 0) as int;
                      return bP.compareTo(aP);
                    });
                    final child = sorted[i];
                    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.warning.withValues(alpha: 0.08) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: i == 0 ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(child.avatarUrl ?? '🧒', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('${_childStats[child.id]?['percent'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
