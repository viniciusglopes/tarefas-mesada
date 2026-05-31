import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'admin_families_screen.dart';
import 'admin_qa_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminService.getStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 1:
        return const AdminFamiliesScreen();
      case 2:
        return const AdminQaScreen();
      default:
        return _buildDashboard();
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
          if (i == 0) _loadStats();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.bug_report), label: 'QA'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Painel Admin', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Tarefas & Mesada', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  onPressed: () async {
                    await AuthService.signOut();
                    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Usuarios', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(icon: Icons.family_restroom, value: '${_stats['total_families'] ?? 0}', label: 'Familias', color: AppColors.primary),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.person, value: '${_stats['total_parents'] ?? 0}', label: 'Pais', color: AppColors.parentBlue),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.child_care, value: '${_stats['total_children'] ?? 0}', label: 'Criancas', color: AppColors.childGreen),
              ],
            ),
            const SizedBox(height: 20),

            Text('Tarefas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(icon: Icons.today, value: '${_stats['tasks_today'] ?? 0}', label: 'Hoje', color: AppColors.parentBlue),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.check_circle, value: '${_stats['tasks_approved'] ?? 0}', label: 'Aprovadas', color: AppColors.success),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.pending, value: '${_stats['tasks_pending_approval'] ?? 0}', label: 'Pendentes', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 20),

            Text('Financeiro', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Saldo total criancas', value: 'R\$ ${(_stats['total_balance'] ?? 0.0).toStringAsFixed(2)}', icon: Icons.account_balance_wallet),
                  const Divider(height: 20),
                  _InfoRow(label: 'XP total distribuido', value: '${_stats['total_xp'] ?? 0} XP', icon: Icons.star),
                  const Divider(height: 20),
                  _InfoRow(label: 'Nivel medio', value: '${(_stats['avg_level'] ?? 0.0).toStringAsFixed(1)}', icon: Icons.trending_up),
                  const Divider(height: 20),
                  _InfoRow(label: 'Maior streak', value: '${_stats['max_streak'] ?? 0} dias', icon: Icons.local_fire_department),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Acoes rapidas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.groups,
                    label: 'Ver Clientes',
                    color: AppColors.parentBlue,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.bug_report,
                    label: 'Testes QA',
                    color: AppColors.xpPurple,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
