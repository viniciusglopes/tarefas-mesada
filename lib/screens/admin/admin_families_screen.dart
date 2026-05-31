import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';

class AdminFamiliesScreen extends StatefulWidget {
  const AdminFamiliesScreen({super.key});

  @override
  State<AdminFamiliesScreen> createState() => _AdminFamiliesScreenState();
}

class _AdminFamiliesScreenState extends State<AdminFamiliesScreen> {
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
  String? _selectedFamilyId;
  Map<String, dynamic>? _familyDetail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final families = await AdminService.getFamilies();
      final parents = await AdminService.getParents();
      final children = await AdminService.getChildren();
      setState(() {
        _families = families;
        _parents = parents;
        _children = children;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showFamilyDetail(String familyId) async {
    setState(() {
      _selectedFamilyId = familyId;
      _familyDetail = null;
    });

    try {
      final detail = await AdminService.getFamilyDetail(familyId);
      setState(() => _familyDetail = detail);
    } catch (_) {}

    if (!mounted) return;
    _showDetailSheet();
  }

  void _showDetailSheet() {
    final family = _familyDetail;
    if (family == null) return;

    final familyData = family['family'] as Map<String, dynamic>;
    final familyParents = family['parents'] as List;
    final familyChildren = family['children'] as List;
    final recentTasks = family['recent_tasks'] as List;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Familia: ${familyData['name'] ?? 'Sem nome'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('ID: ${_selectedFamilyId ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            const Text('Pais/Maes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (familyParents.isEmpty)
              const Text('Nenhum pai cadastrado', style: TextStyle(color: AppColors.textSecondary))
            else
              ...familyParents.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.parentBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.parentBlue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.parentBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(p['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),

            const SizedBox(height: 16),
            const Text('Criancas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (familyChildren.isEmpty)
              const Text('Nenhuma crianca cadastrada', style: TextStyle(color: AppColors.textSecondary))
            else
              ...familyChildren.map((c) {
                final balance = ((c['balance'] ?? 0) as num).toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.childGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.childGreen.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Text(c['avatar_url'] ?? '🧒', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('@${c['username'] ?? ''} • Lv ${c['level'] ?? 1} • ${c['xp'] ?? 0} XP', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('R\$ ${balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if ((c['streak'] ?? 0) > 0)
                            Text('🔥 ${c['streak']}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),
            Text('Ultimas tarefas (${recentTasks.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (recentTasks.isEmpty)
              const Text('Nenhuma tarefa registrada', style: TextStyle(color: AppColors.textSecondary))
            else
              ...recentTasks.map((t) {
                final template = t['task_templates'] as Map<String, dynamic>?;
                final status = t['status'] as String? ?? 'pending';
                final statusColor = switch (status) {
                  'approved' => AppColors.success,
                  'completed' => AppColors.warning,
                  'rejected' => AppColors.danger,
                  _ => AppColors.textSecondary,
                };
                final statusLabel = switch (status) {
                  'approved' => 'Aprovada',
                  'completed' => 'Aguardando',
                  'rejected' => 'Rejeitada',
                  _ => 'Pendente',
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(template?['icon'] ?? '📋', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(template?['title'] ?? 'Tarefa', style: const TextStyle(fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${_families.length} familias', style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _families.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('📭', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 8),
                    Text('Nenhum cliente cadastrado', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _families.length,
                itemBuilder: (context, index) {
                  final family = _families[index];
                  final familyId = family['id'] as String;
                  final familyParents = _parents.where((p) => p['family_id'] == familyId).toList();
                  final familyChildren = _children.where((c) => c['family_id'] == familyId).toList();
                  final totalBalance = familyChildren.fold<double>(0, (sum, c) => sum + ((c['balance'] ?? 0) as num).toDouble());
                  final createdAt = family['created_at'] != null ? DateTime.tryParse(family['created_at']) : null;

                  return GestureDetector(
                    onTap: () => _showFamilyDetail(familyId),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.family_restroom, color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(family['name'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (familyParents.isNotEmpty)
                                      Text(familyParents.map((p) => p['name']).join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MiniChip(icon: Icons.child_care, label: '${familyChildren.length} filhos', color: AppColors.childGreen),
                              const SizedBox(width: 8),
                              _MiniChip(icon: Icons.account_balance_wallet, label: 'R\$ ${totalBalance.toStringAsFixed(0)}', color: AppColors.parentBlue),
                              const Spacer(),
                              if (createdAt != null)
                                Text(
                                  '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
