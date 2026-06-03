import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../models/child.dart';
import '../../services/task_service.dart';
import '../../services/child_service.dart';

class TasksManageScreen extends StatefulWidget {
  final String familyId;
  const TasksManageScreen({super.key, required this.familyId});

  @override
  State<TasksManageScreen> createState() => _TasksManageScreenState();
}

class _TasksManageScreenState extends State<TasksManageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TaskTemplate> _templates = [];
  List<Child> _children = [];
  bool _loading = true;

  static const _frequencyLabels = {
    'daily': 'Diaria',
    'weekly': 'Semanal',
    'once': 'Unica',
  };

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
    try {
      final templates = await TaskService.getTaskTemplates(widget.familyId);
      final children = await ChildService.getChildren(widget.familyId);
      setState(() {
        _templates = templates;
        _children = children;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Modelos'),
            Tab(text: 'Atribuir'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildAssignTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateForm(),
        backgroundColor: AppColors.childGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('📋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Nenhuma tarefa cadastrada', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('Crie tarefas para seus filhos!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final t = _templates[index];
        final assignedChild = t.assignedTo != null
            ? _children.where((c) => c.id == t.assignedTo).firstOrNull
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
                        Text('+${t.xpReward} XP', style: const TextStyle(fontSize: 12, color: AppColors.xpPurple)),
                        if (t.moneyReward > 0) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                          Text('R\$ ${t.moneyReward.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.childGreen)),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.parentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _frequencyLabels[t.frequency] ?? t.frequency,
                            style: const TextStyle(fontSize: 10, color: AppColors.parentBlue),
                          ),
                        ),
                      ],
                    ),
                    if (assignedChild != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${assignedChild.emoji} ${assignedChild.name}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
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
                  await TaskService.deleteTaskTemplate(t.id);
                  _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignTab() {
    if (_children.isEmpty) {
      return const Center(child: Text('Nenhum filho cadastrado', style: TextStyle(color: AppColors.textSecondary)));
    }
    if (_templates.isEmpty) {
      return const Center(child: Text('Crie um modelo de tarefa primeiro', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Selecione o filho e a tarefa para atribuir:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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
              leading: child.avatarWidget(fontSize: 24),
              title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${child.xp} XP • Nivel ${child.level}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              children: _templates.map((template) => ListTile(
                leading: Text(template.icon, style: const TextStyle(fontSize: 24)),
                title: Text(template.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '+${template.xpReward} XP${template.moneyReward > 0 ? ' • R\$ ${template.moneyReward.toStringAsFixed(2)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.xpPurple),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_task, color: AppColors.childGreen),
                  onPressed: () => _confirmAssign(child, template),
                ),
              )).toList(),
            ),
          ),
        )),
      ],
    );
  }

  void _confirmAssign(Child child, TaskTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Atribuir Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(template.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Para: ${child.name}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              '+${template.xpReward} XP${template.moneyReward > 0 ? ' • R\$ ${template.moneyReward.toStringAsFixed(2)}' : ''}',
              style: const TextStyle(color: AppColors.xpPurple),
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
              await TaskService.assignTaskToChild(
                templateId: template.id,
                childId: child.id,
                familyId: widget.familyId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tarefa atribuida a ${child.name}'),
                    backgroundColor: AppColors.childGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.childGreen, foregroundColor: Colors.white),
            child: const Text('Atribuir'),
          ),
        ],
      ),
    );
  }

  void _showTemplateForm({TaskTemplate? template}) {
    final isEdit = template != null;
    final titleCtrl = TextEditingController(text: template?.title ?? '');
    final descCtrl = TextEditingController(text: template?.description ?? '');
    final xpCtrl = TextEditingController(text: template != null ? '${template.xpReward}' : '10');
    final moneyCtrl = TextEditingController(text: template != null ? template.moneyReward.toStringAsFixed(2) : '0');
    String frequency = template?.frequency ?? 'daily';
    String icon = template?.icon ?? '📋';
    String? assignedTo = template?.assignedTo;

    final icons = ['📋', '🧹', '📚', '🛏️', '🍽️', '🐕', '🧺', '🗑️', '🏃', '🎹', '✏️', '🦷'];

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
                Text(isEdit ? 'Editar Tarefa' : 'Nova Tarefa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => icon = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: icon == e ? AppColors.childGreen : AppColors.border, width: icon == e ? 2 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nome da tarefa')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao (opcional)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xpCtrl,
                        decoration: const InputDecoration(labelText: 'XP'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: moneyCtrl,
                        decoration: const InputDecoration(labelText: 'R\$ (opcional)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Frequencia', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: ['daily', 'weekly', 'once'].map((f) {
                    final selected = frequency == f;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(_frequencyLabels[f] ?? f),
                          selected: selected,
                          onSelected: (_) => setSheetState(() => frequency = f),
                          selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.childGreen : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_children.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Atribuir a (opcional)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: assignedTo == null,
                        onSelected: (_) => setSheetState(() => assignedTo = null),
                        selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                        labelStyle: TextStyle(fontSize: 12, color: assignedTo == null ? AppColors.childGreen : AppColors.textSecondary),
                      ),
                      ..._children.map((c) => ChoiceChip(
                        label: Text('${c.emoji} ${c.name}'),
                        selected: assignedTo == c.id,
                        onSelected: (_) => setSheetState(() => assignedTo = c.id),
                        selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                        labelStyle: TextStyle(fontSize: 12, color: assignedTo == c.id ? AppColors.childGreen : AppColors.textSecondary),
                      )),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await TaskService.updateTaskTemplate(
                          templateId: template.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          icon: icon,
                          xpReward: int.tryParse(xpCtrl.text) ?? 10,
                          moneyReward: double.tryParse(moneyCtrl.text.replaceAll(',', '.')) ?? 0,
                          frequency: frequency,
                          assignedTo: assignedTo,
                        );
                      } else {
                        await TaskService.createTaskTemplate(
                          familyId: widget.familyId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          icon: icon,
                          xpReward: int.tryParse(xpCtrl.text) ?? 10,
                          moneyReward: double.tryParse(moneyCtrl.text.replaceAll(',', '.')) ?? 0,
                          frequency: frequency,
                          assignedTo: assignedTo,
                        );
                      }
                      _load();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.childGreen, foregroundColor: Colors.white),
                    child: Text(isEdit ? 'Salvar' : 'Criar Tarefa'),
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
