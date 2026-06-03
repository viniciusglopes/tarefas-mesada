import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/penalty.dart';
import '../../services/penalty_service.dart';
import '../../services/child_service.dart';
import '../../services/supabase_service.dart';

class PenaltiesScreen extends StatefulWidget {
  final String familyId;
  const PenaltiesScreen({super.key, required this.familyId});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PenaltyTemplate> _templates = [];
  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final templates = await PenaltyService.getTemplates(widget.familyId);
    final children = await ChildService.getChildren(widget.familyId);
    setState(() {
      _templates = templates;
      _children = children;
      _loading = false;
    });
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'light':
        return AppColors.warning;
      case 'medium':
        return Colors.orange;
      case 'severe':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'light':
        return 'Leve';
      case 'medium':
        return 'Media';
      case 'severe':
        return 'Grave';
      default:
        return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penalidades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aplicar'),
            Tab(text: 'Modelos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildApplyTab(),
                _buildTemplatesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTemplateForm,
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildApplyTab() {
    if (_children.isEmpty) {
      return const Center(child: Text('Nenhum filho cadastrado', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Selecione o filho e a penalidade:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ..._children.map((child) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
                child: Text(child.avatarUrl ?? '🧒', style: const TextStyle(fontSize: 24)),
              ),
              title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${child.xp} XP • R\$ ${child.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              children: _templates.isEmpty
                  ? [const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Crie um modelo de penalidade primeiro', style: TextStyle(color: AppColors.textSecondary)),
                    )]
                  : _templates.map((template) => ListTile(
                      leading: Text(template.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(template.title, style: const TextStyle(fontSize: 14)),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _severityColor(template.severity).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _severityLabel(template.severity),
                              style: TextStyle(fontSize: 10, color: _severityColor(template.severity), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (template.xpDiscount > 0) Text('-${template.xpDiscount} XP ', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                          if (template.moneyDiscount > 0) Text('-R\$ ${template.moneyDiscount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.gavel, color: AppColors.danger),
                        onPressed: () => _confirmApply(child, template),
                      ),
                    )).toList(),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('⚠️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Nenhum modelo de penalidade', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('Crie um modelo para aplicar penalidades', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final t = _templates[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _severityColor(t.severity).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(t.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _severityColor(t.severity).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _severityLabel(t.severity),
                            style: TextStyle(fontSize: 11, color: _severityColor(t.severity), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (t.xpDiscount > 0) Text('-${t.xpDiscount} XP', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                        if (t.xpDiscount > 0 && t.moneyDiscount > 0) const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                        if (t.moneyDiscount > 0) Text('-R\$ ${t.moneyDiscount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.parentBlue, size: 22),
                onPressed: () => _showTemplateForm(template: t),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                onPressed: () async {
                  await PenaltyService.deleteTemplate(t.id);
                  _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmApply(Child child, PenaltyTemplate template) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aplicar Penalidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(template.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Para: ${child.name}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (template.xpDiscount > 0)
              Text('-${template.xpDiscount} XP', style: const TextStyle(color: AppColors.danger, fontSize: 16, fontWeight: FontWeight.bold)),
            if (template.moneyDiscount > 0)
              Text('-R\$ ${template.moneyDiscount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.danger, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PenaltyService.applyPenalty(
                childId: child.id,
                parentId: SupabaseService.currentUser!.id,
                templateId: template.id,
                xpLost: template.xpDiscount,
                moneyLost: template.moneyDiscount,
                reason: reasonController.text.isEmpty ? null : reasonController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Penalidade aplicada a ${child.name}'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showTemplateForm({PenaltyTemplate? template}) {
    final isEdit = template != null;
    final titleCtrl = TextEditingController(text: template?.title ?? '');
    final xpCtrl = TextEditingController(text: template != null ? '${template.xpDiscount}' : '10');
    final moneyCtrl = TextEditingController(text: template != null ? template.moneyDiscount.toStringAsFixed(2) : '0');
    String severity = template?.severity ?? 'light';
    String icon = template?.icon ?? '⚠️';

    final icons = ['⚠️', '🚫', '❌', '💢', '🔴', '⛔', '📵', '🗑️'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Editar Penalidade' : 'Novo Modelo de Penalidade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: icons.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => icon = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: icon == e ? AppColors.danger : AppColors.border, width: icon == e ? 2 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da penalidade'),
                ),
                const SizedBox(height: 12),
                const Text('Gravidade', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: ['light', 'medium', 'severe'].map((s) {
                    final selected = severity == s;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(_severityLabel(s)),
                          selected: selected,
                          onSelected: (_) => setSheetState(() => severity = s),
                          selectedColor: _severityColor(s).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selected ? _severityColor(s) : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xpCtrl,
                        decoration: const InputDecoration(labelText: 'XP a perder'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: moneyCtrl,
                        decoration: const InputDecoration(labelText: 'R\$ a perder'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await PenaltyService.updateTemplate(
                          templateId: template.id,
                          title: titleCtrl.text.trim(),
                          icon: icon,
                          severity: severity,
                          xpDiscount: int.tryParse(xpCtrl.text) ?? 0,
                          moneyDiscount: double.tryParse(moneyCtrl.text.replaceAll(',', '.')) ?? 0,
                        );
                      } else {
                        await PenaltyService.createTemplate(
                          familyId: widget.familyId,
                          title: titleCtrl.text.trim(),
                          icon: icon,
                          severity: severity,
                          xpDiscount: int.tryParse(xpCtrl.text) ?? 0,
                          moneyDiscount: double.tryParse(moneyCtrl.text.replaceAll(',', '.')) ?? 0,
                        );
                      }
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEdit ? 'Salvar' : 'Criar Modelo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
