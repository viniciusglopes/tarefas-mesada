import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'penalties_screen.dart';
import 'rewards_screen.dart';
import 'manage_children_screen.dart';
import 'messages_screen.dart';
import 'tasks_screen.dart';
import 'allowance_screen.dart';
import 'reports_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  Map<String, dynamic>? _parent;
  List<Child> _children = [];
  List<Task> _pendingTasks = [];
  List<Task> _todayTasks = [];
  int _pendingApprovals = 0;
  int _unreadMessages = 0;
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _familyId => _parent?['family_id'] as String? ?? '';

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
          .select('*, task_templates(*)')
          .eq('family_id', parent['family_id'])
          .eq('status', 'completed')
          .order('completed_at');

      final today = DateTime.now().toIso8601String().split('T').first;
      final todayTasks = await client
          .from('tasks')
          .select('*, task_templates(*)')
          .eq('family_id', parent['family_id'])
          .eq('date', today);

      int unread = 0;
      final childList = (children as List).map((e) => Child.fromJson(e)).toList();
      for (final child in childList) {
        final msgs = await client
            .from('messages')
            .select('id')
            .eq('family_id', parent['family_id'])
            .eq('child_id', child.id)
            .eq('is_from_parent', false)
            .eq('is_read', false);
        unread += (msgs as List).length;
      }

      setState(() {
        _parent = parent;
        _children = childList;
        _pendingTasks = (pending as List).map((e) => Task.fromJson(e)).toList();
        _todayTasks = (todayTasks as List).map((e) => Task.fromJson(e)).toList();
        _pendingApprovals = _pendingTasks.length;
        _unreadMessages = unread;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _parent = null;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  int get _todayCompleted => _todayTasks.where((t) => t.status == TaskStatus.approved).length;
  int get _todayTotal => _todayTasks.length;
  String get _completionPercent => _todayTotal == 0 ? '0%' : '${(_todayCompleted * 100 / _todayTotal).round()}%';

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 1:
        return _buildApprovalsScreen();
      case 2:
        return ReportsScreen(familyId: _familyId, children: _children);
      case 3:
        return ParentMessagesScreen(familyId: _familyId);
      case 4:
        return _buildSettingsScreen();
      default:
        return _buildHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_parent == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Nao foi possivel carregar seus dados', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () { setState(() => _loading = true); _loadData(); },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _loadData();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingApprovals > 0,
              label: Text('$_pendingApprovals'),
              child: const Icon(Icons.check_circle),
            ),
            label: 'Aprovar',
          ),
          const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Relatorios'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadMessages > 0,
              label: Text('$_unreadMessages'),
              child: const Icon(Icons.chat),
            ),
            label: 'Mensagens',
          ),
          const NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${_greeting()}, ${_parent?['name'] ?? ''}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _QuickAction(
                  icon: '📋', label: 'Tarefas', color: AppColors.childGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TasksManageScreen(familyId: _familyId))).then((_) => _loadData()),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: '💰', label: 'Mesada', color: AppColors.parentBlue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllowanceScreen(familyId: _familyId))).then((_) => _loadData()),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: '🎁', label: 'Recom-\npensas', color: AppColors.success,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RewardsManageScreen(familyId: _familyId))),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: '⚠️', label: 'Penali-\ndade', color: AppColors.danger,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PenaltiesScreen(familyId: _familyId))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _MetricCard(value: '$_pendingApprovals', label: 'Aprovacoes\npendentes', color: AppColors.warning),
                const SizedBox(width: 12),
                _MetricCard(value: _completionPercent, label: 'Conclusao\nhoje', color: AppColors.childGreen),
                const SizedBox(width: 12),
                _MetricCard(
                  value: 'R\$ ${_children.fold<double>(0, (sum, c) => sum + c.balance).toStringAsFixed(0)}',
                  label: 'Total\nmesada',
                  color: AppColors.parentBlue,
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                      const Text('Nenhum filho cadastrado'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageChildrenScreen(familyId: _familyId))),
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
    );
  }

  Widget _buildApprovalsScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprovacoes Pendentes')),
      body: _pendingTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('✅', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('Nenhuma aprovacao pendente', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingTasks.length,
                itemBuilder: (context, index) {
                  final task = _pendingTasks[index];
                  final childName = _children
                      .where((c) => c.id == task.childId)
                      .map((c) => c.name)
                      .firstOrNull ?? 'Filho';

                  return Dismissible(
                    key: Key(task.id),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text('Aprovar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Rejeitar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.close, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await TaskService.approveTask(task.id, SupabaseService.currentUser!.id);
                        _loadData();
                        return true;
                      } else {
                        await TaskService.rejectTask(task.id);
                        _loadData();
                        return true;
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(task.template?.icon ?? '📋', style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.template?.title ?? 'Tarefa', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(childName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(
                                  '+${task.template?.xpReward ?? 0} XP • R\$ ${(task.template?.moneyReward ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.xpPurple),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swipe, size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFE8F0FE),
                  child: Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(_parent?['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_parent?['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.task_alt,
            title: 'Tarefas',
            subtitle: 'Criar e gerenciar tarefas dos filhos',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TasksManageScreen(familyId: _familyId))),
          ),
          _SettingsTile(
            icon: Icons.savings,
            title: 'Mesada',
            subtitle: 'Configurar valor, frequencia e fechar periodo',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllowanceScreen(familyId: _familyId))),
          ),
          _SettingsTile(
            icon: Icons.gavel,
            title: 'Penalidades',
            subtitle: 'Gerenciar modelos de penalidade',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PenaltiesScreen(familyId: _familyId))),
          ),
          _SettingsTile(
            icon: Icons.card_giftcard,
            title: 'Recompensas',
            subtitle: 'Gerenciar catalogo de recompensas',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RewardsManageScreen(familyId: _familyId))),
          ),
          _SettingsTile(
            icon: Icons.people,
            title: 'Gerenciar Filhos',
            subtitle: 'Adicionar, editar e permissoes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageChildrenScreen(familyId: _familyId))),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.signOut();
                await SessionService.clearChildSession();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Sair', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.parentBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
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
                  if (child.allowanceAmount > 0)
                    Text(
                      'Mesada: R\$ ${child.allowanceAmount.toStringAsFixed(2)} (${child.allowanceFrequency == 'monthly' ? 'mensal' : 'semanal'})',
                      style: const TextStyle(fontSize: 11, color: AppColors.parentBlue),
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
