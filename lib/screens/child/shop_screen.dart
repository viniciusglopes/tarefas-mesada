import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/reward.dart';
import '../../services/reward_service.dart';

class ShopScreen extends StatefulWidget {
  final Child child;
  const ShopScreen({super.key, required this.child});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Reward> _rewards = [];
  bool _loading = true;
  String _selectedCategory = 'all';
  late double _balance;

  static const _categories = {
    'all': 'Todos',
    'leisure': 'Lazer',
    'trips': 'Passeios',
    'gifts': 'Presentes',
    'money': 'Dinheiro',
  };

  static const _categoryIcons = {
    'leisure': '🎮',
    'trips': '🎡',
    'gifts': '🎁',
    'money': '💵',
  };

  @override
  void initState() {
    super.initState();
    _balance = widget.child.balance;
    _load();
  }

  Future<void> _load() async {
    final rewards = await RewardService.getRewards(widget.child.familyId);
    setState(() {
      _rewards = rewards;
      _loading = false;
    });
  }

  List<Reward> get _filteredRewards {
    if (_selectedCategory == 'all') return _rewards;
    return _rewards.where((r) => r.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loja de Recompensas'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.childGreen, AppColors.childGreen.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seu Saldo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            'R\$ ${_balance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _categories.entries.map((e) {
                      final selected = _selectedCategory == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(e.value),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedCategory = e.key),
                          selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.childGreen,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.childGreen : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _filteredRewards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🏪', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text('Nenhuma recompensa disponivel', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRewards.length,
                          itemBuilder: (context, index) {
                            final reward = _filteredRewards[index];
                            final canAfford = _balance >= reward.price;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: canAfford ? AppColors.childGreen.withValues(alpha: 0.3) : AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.childGreen.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(reward.icon, style: const TextStyle(fontSize: 28)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reward.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        if (reward.description != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            reward.description!,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'R\$ ${reward.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: canAfford ? AppColors.childGreen : AppColors.danger,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _categoryIcons[reward.category] ?? '🎁',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: canAfford ? () => _confirmRedeem(reward) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.childGreen,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(72, 38),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: const Text('Resgatar', style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _confirmRedeem(Reward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Resgate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reward.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(reward.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('R\$ ${reward.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.childGreen)),
            const SizedBox(height: 4),
            Text(
              'Saldo apos: R\$ ${(_balance - reward.price).toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              final success = await RewardService.redeemWithBalanceCheck(
                childId: widget.child.id,
                rewardId: reward.id,
                price: reward.price,
                currentBalance: _balance,
              );
              if (success) {
                setState(() => _balance -= reward.price);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reward.icon} ${reward.title} resgatado!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.childGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
