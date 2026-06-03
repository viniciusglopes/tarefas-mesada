import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/reward.dart';
import '../../services/reward_service.dart';

class RewardsManageScreen extends StatefulWidget {
  final String familyId;
  const RewardsManageScreen({super.key, required this.familyId});

  @override
  State<RewardsManageScreen> createState() => _RewardsManageScreenState();
}

class _RewardsManageScreenState extends State<RewardsManageScreen> {
  List<Reward> _rewards = [];
  bool _loading = true;

  static const _categoryIcons = {
    'leisure': '🎮',
    'trips': '🎡',
    'gifts': '🎁',
    'money': '💵',
  };

  static const _categoryLabels = {
    'leisure': 'Lazer',
    'trips': 'Passeios',
    'gifts': 'Presentes',
    'money': 'Dinheiro',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rewards = await RewardService.getRewards(widget.familyId);
    setState(() {
      _rewards = rewards;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rewards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🎁', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('Nenhuma recompensa cadastrada', style: TextStyle(color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('Crie recompensas para seus filhos!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final r = _rewards[index];
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.childGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(r.icon, style: const TextStyle(fontSize: 28)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'R\$ ${r.price.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.childGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.parentBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_categoryIcons[r.category] ?? '🎁'} ${_categoryLabels[r.category] ?? r.category}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.parentBlue),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.parentBlue, size: 22),
                            onPressed: () => _showEdit(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                            onPressed: () async {
                              await RewardService.deleteReward(r.id);
                              _load();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreate,
        backgroundColor: AppColors.childGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Recompensa'),
      ),
    );
  }

  void _showRewardForm({Reward? reward}) {
    final isEdit = reward != null;
    final titleCtrl = TextEditingController(text: reward?.title ?? '');
    final descCtrl = TextEditingController(text: reward?.description ?? '');
    final priceCtrl = TextEditingController(text: reward != null ? reward.price.toStringAsFixed(2) : '');
    String category = reward?.category ?? 'gifts';
    String icon = reward?.icon ?? '🎁';

    final icons = ['🎁', '🎮', '🎡', '💵', '🍕', '🎬', '📱', '🏊', '🎪', '🎂', '👟', '📚'];

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
                Text(isEdit ? 'Editar Recompensa' : 'Nova Recompensa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nome da recompensa')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descricao (opcional)')),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Preco (R\$)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                const Text('Categoria', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _categoryLabels.entries.map((e) {
                    final selected = category == e.key;
                    return ChoiceChip(
                      label: Text('${_categoryIcons[e.key]} ${e.value}'),
                      selected: selected,
                      onSelected: (_) => setSheetState(() => category = e.key),
                      selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                      labelStyle: TextStyle(fontSize: 12, color: selected ? AppColors.childGreen : AppColors.textSecondary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || priceCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await RewardService.updateReward(
                          rewardId: reward.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          icon: icon,
                          price: double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
                          category: category,
                        );
                      } else {
                        await RewardService.createReward(
                          familyId: widget.familyId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          icon: icon,
                          price: double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
                          category: category,
                        );
                      }
                      _load();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.childGreen, foregroundColor: Colors.white),
                    child: Text(isEdit ? 'Salvar' : 'Criar Recompensa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreate() => _showRewardForm();
  void _showEdit(Reward reward) => _showRewardForm(reward: reward);
}
