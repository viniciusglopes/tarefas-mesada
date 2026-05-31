import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../models/child.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  Map<String, dynamic>? _parent;
  List<Child> _children = [];
  int _pendingApprovals = 0;
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = SupabaseService.currentUser!.id;
      final client = SupabaseService.client;

      final parent = await client
          .from('parents')
          .select()
          .eq('id', userId)
          .single();

      final children = await client
          .from('children')
          .select()
          .eq('family_id', parent['family_id'])
          .order('name');

      final pending = await client
          .from('tasks')
          .select()
          .eq('family_id', parent['family_id'])
          .eq('status', 'completed')
          .count();

      setState(() {
        _parent = parent;
        _children = (children as List).map((e) => Child.fromJson(e)).toList();
        _pendingApprovals = pending.count;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${_greeting()}, ${_parent?['name'] ?? ''}! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Familia ${_parent?['family_id'] != null ? '' : ''}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  _QuickAction(icon: '📋', label: 'Nova\nTarefa', color: AppColors.parentBlue, onTap: () {}),
                  const SizedBox(width: 12),
                  _QuickAction(icon: '⚠️', label: 'Penali-\ndade', color: AppColors.danger, onTap: () {}),
                  const SizedBox(width: 12),
                  _QuickAction(icon: '🎁', label: 'Novo\nPremio', color: AppColors.success, onTap: () {}),
                  const SizedBox(width: 12),
                  _QuickAction(icon: '📊', label: 'Fechar\nPeriodo', color: AppColors.xpPurple, onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),

              // Metrics
              Row(
                children: [
                  _MetricCard(value: '$_pendingApprovals', label: 'Aprovacoes\npendentes', color: AppColors.warning),
                  const SizedBox(width: 12),
                  _MetricCard(value: '0%', label: 'Conclusao\nhoje', color: AppColors.childGreen),
                  const SizedBox(width: 12),
                  _MetricCard(value: 'R\$ 0', label: 'Total\nmesada', color: AppColors.parentBlue),
                ],
              ),
              const SizedBox(height: 24),

              // Children summary
              Text(
                'Filhos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_children.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('👶', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        const Text('Nenhum filho cadastrado'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Filho'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.parentBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._children.map((child) => _ChildCard(child: child)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tarefas'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Aprovar'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Relatorios'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
              child: Text(child.avatarUrl ?? '🧒', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    'Nivel ${child.level} • ${child.xp} XP • R\$ ${child.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (child.streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('🔥 ${child.streak}', style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
