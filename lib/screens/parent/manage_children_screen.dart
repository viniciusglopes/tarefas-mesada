import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../services/child_service.dart';
import '../../services/task_service.dart';

class ManageChildrenScreen extends StatefulWidget {
  final String familyId;
  const ManageChildrenScreen({super.key, required this.familyId});

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final children = await ChildService.getChildren(widget.familyId);
      setState(() {
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
      appBar: AppBar(title: const Text('Gerenciar Filhos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('👶', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('Nenhum filho cadastrado', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final child = _children[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.childGreen.withValues(alpha: 0.1),
                              child: Text(child.avatarUrl ?? '🧒', style: const TextStyle(fontSize: 28)),
                            ),
                            title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nivel ${child.level} • ${child.xp} XP',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.parentBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '@${child.username}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.parentBlue),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                                          SizedBox(width: 3),
                                          Text(
                                            'PIN: ****',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.parentBlue),
                              onPressed: () => _showEditChild(child),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                _InfoChip(icon: '💰', value: 'R\$ ${child.balance.toStringAsFixed(2)}'),
                                const SizedBox(width: 8),
                                _InfoChip(icon: '🔥', value: '${child.streak} dias'),
                                const SizedBox(width: 8),
                                _InfoChip(icon: '🏆', value: 'Record: ${child.bestStreak}'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => _showPermissions(child),
                                  child: const Text('Permissoes', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChild,
        backgroundColor: AppColors.parentBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar Filho'),
      ),
    );
  }

  void _showAddChild() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String gender = 'M';
    String avatar = '🧒';
    String avatarCategory = 'people';
    DateTime? birthDate;

    final avatarCategories = <String, List<String>>{
      'people': ['🧒', '👦', '👧', '🧒🏻', '👦🏻', '👧🏻', '🧒🏽', '👦🏽', '👧🏽', '🧒🏾', '👦🏾', '👧🏾'],
      'characters': ['🦸', '🦸‍♂️', '🦸‍♀️', '🧙', '🧙‍♂️', '🧙‍♀️', '🧛', '🧜‍♀️', '🧝', '🧝‍♀️', '🤴', '👸'],
      'animals': ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🦁', '🐯', '🐸', '🐵', '🦄'],
    };
    final categoryLabels = {'people': 'Pessoas', 'characters': 'Personagens', 'animals': 'Animais'};

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
                const Text('Adicionar Filho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Avatar', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: categoryLabels.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                      selected: avatarCategory == entry.key,
                      onSelected: (_) => setSheetState(() => avatarCategory = entry.key),
                      selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: avatarCategories[avatarCategory]!.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => avatar = e),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: avatar == e ? AppColors.childGreen : AppColors.border,
                          width: avatar == e ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username (para login)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(labelText: 'PIN (4 digitos)'),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                const Text('Data de Nascimento', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate ?? DateTime(2018, 1, 1),
                      firstDate: DateTime(2005),
                      lastDate: DateTime.now(),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) setSheetState(() => birthDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          birthDate != null ? '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}' : 'Selecione a data',
                          style: TextStyle(color: birthDate != null ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Genero', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Menino'),
                        selected: gender == 'M',
                        onSelected: (_) => setSheetState(() => gender = 'M'),
                        selectedColor: AppColors.parentBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Menina'),
                        selected: gender == 'F',
                        onSelected: (_) => setSheetState(() => gender = 'F'),
                        selectedColor: Colors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || pinCtrl.text.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preencha todos os campos (PIN = 4 digitos)'), backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await ChildService.createChild(
                        familyId: widget.familyId,
                        name: nameCtrl.text.trim(),
                        username: usernameCtrl.text.trim().toLowerCase(),
                        pin: pinCtrl.text,
                        gender: gender,
                        birthDate: birthDate,
                        avatarUrl: avatar,
                      );
                      _load();
                      _showDefaultTasksPrompt();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.parentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cadastrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDefaultTasksPrompt() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tarefas Padrao'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Deseja cadastrar tarefas padrao do dia a dia?\n\nInclui escovar os dentes, arrumar a cama, fazer o dever de casa e mais.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nao, obrigado'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await TaskService.createDefaultTasks(familyId: widget.familyId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('18 tarefas padrao cadastradas!'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.childGreen, foregroundColor: Colors.white),
            child: const Text('Sim, cadastrar!'),
          ),
        ],
      ),
    );
  }

  void _showEditChild(Child child) {
    final nameCtrl = TextEditingController(text: child.name);
    final allowanceCtrl = TextEditingController(text: child.allowanceAmount > 0 ? child.allowanceAmount.toStringAsFixed(2) : '');
    String avatar = child.avatarUrl ?? '🧒';
    String gender = child.gender ?? 'M';
    String allowanceFreq = child.allowanceFrequency;
    String avatarCategory = 'people';

    final avatarCategories = <String, List<String>>{
      'people': ['🧒', '👦', '👧', '🧒🏻', '👦🏻', '👧🏻', '🧒🏽', '👦🏽', '👧🏽', '🧒🏾', '👦🏾', '👧🏾'],
      'characters': ['🦸', '🦸‍♂️', '🦸‍♀️', '🧙', '🧙‍♂️', '🧙‍♀️', '🧛', '🧜‍♀️', '🧝', '🧝‍♀️', '🤴', '👸'],
      'animals': ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🦁', '🐯', '🐸', '🐵', '🦄'],
    };
    final categoryLabels = {'people': 'Pessoas', 'characters': 'Personagens', 'animals': 'Animais'};

    // Detect which category the current avatar belongs to
    for (final entry in avatarCategories.entries) {
      if (entry.value.contains(avatar)) {
        avatarCategory = entry.key;
        break;
      }
    }

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
                Text('Editar ${child.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Avatar', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: categoryLabels.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                      selected: avatarCategory == entry.key,
                      onSelected: (_) => setSheetState(() => avatarCategory = entry.key),
                      selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: avatarCategories[avatarCategory]!.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => avatar = e),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: avatar == e ? AppColors.childGreen : AppColors.border,
                          width: avatar == e ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                const Text('Genero', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Menino'),
                        selected: gender == 'M',
                        onSelected: (_) => setSheetState(() => gender = 'M'),
                        selectedColor: AppColors.parentBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Menina'),
                        selected: gender == 'F',
                        onSelected: (_) => setSheetState(() => gender = 'F'),
                        selectedColor: Colors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Mesada', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: allowanceCtrl,
                  decoration: const InputDecoration(labelText: 'Valor da mesada (R\$)', prefixText: 'R\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Semanal'),
                        selected: allowanceFreq == 'weekly',
                        onSelected: (_) => setSheetState(() => allowanceFreq = 'weekly'),
                        selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                        labelStyle: TextStyle(fontSize: 12, color: allowanceFreq == 'weekly' ? AppColors.childGreen : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Mensal'),
                        selected: allowanceFreq == 'monthly',
                        onSelected: (_) => setSheetState(() => allowanceFreq = 'monthly'),
                        selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                        labelStyle: TextStyle(fontSize: 12, color: allowanceFreq == 'monthly' ? AppColors.childGreen : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showChangePin(ctx, child),
                        child: const Text('Alterar PIN'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ChildService.updateChild(
                            childId: child.id,
                            name: nameCtrl.text.trim(),
                            avatarUrl: avatar,
                            avatarType: 'emoji',
                            gender: gender,
                            allowanceAmount: double.tryParse(allowanceCtrl.text.replaceAll(',', '.')) ?? 0,
                            allowanceFrequency: allowanceFreq,
                          );
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.parentBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePin(BuildContext parentCtx, Child child) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Novo PIN para ${child.name}'),
        content: TextField(
          controller: pinCtrl,
          decoration: const InputDecoration(labelText: 'Novo PIN (4 digitos)'),
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length != 4) return;
              Navigator.pop(ctx);
              await ChildService.updatePin(childId: child.id, newPin: pinCtrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN alterado!'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showPermissions(Child child) async {
    final perms = await ChildService.getPermissions(child.id);

    final labels = {
      'can_see_balance': 'Ver saldo',
      'can_see_xp': 'Ver XP',
      'can_mark_tasks': 'Marcar tarefas',
      'can_see_cards': 'Ver cartas',
      'can_see_ranking': 'Ver ranking',
      'can_use_shop': 'Usar loja',
      'can_send_messages': 'Enviar mensagens',
    };

    final values = Map<String, bool>.from({
      for (final key in labels.keys) key: perms[key] ?? true,
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permissoes de ${child.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: labels.entries.map((e) => GestureDetector(
                  onTap: () => setSheetState(() => values[e.key] = !values[e.key]!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: values[e.key]! ? AppColors.success : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: values[e.key]! ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ChildService.updatePermissions(childId: child.id, permissions: values);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permissoes salvas!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
                  child: const Text('Salvar Permissoes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String value;

  const _InfoChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$icon $value', style: const TextStyle(fontSize: 11)),
    );
  }
}
