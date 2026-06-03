import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../services/child_service.dart';

class AllowanceScreen extends StatefulWidget {
  final String familyId;
  const AllowanceScreen({super.key, required this.familyId});

  @override
  State<AllowanceScreen> createState() => _AllowanceScreenState();
}

class _AllowanceScreenState extends State<AllowanceScreen> {
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

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      default:
        return freq;
    }
  }

  int _periodDays(String freq) {
    return freq == 'monthly' ? 30 : 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesada')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? const Center(child: Text('Nenhum filho cadastrado', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Configuracao de Mesada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Configure o valor e frequencia da mesada de cada filho', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ..._children.map((child) => _ChildAllowanceCard(
                        child: child,
                        onEdit: () => _showEditAllowance(child),
                        onClosePeriod: () => _confirmClosePeriod(child),
                        onViewHistory: () => _showHistory(child),
                      )),
                    ],
                  ),
                ),
    );
  }

  void _showEditAllowance(Child child) {
    final amountCtrl = TextEditingController(text: child.allowanceAmount > 0 ? child.allowanceAmount.toStringAsFixed(2) : '');
    String frequency = child.allowanceFrequency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mesada de ${child.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valor da mesada (R\$)',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text('Frequencia', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Semanal'),
                      selected: frequency == 'weekly',
                      onSelected: (_) => setSheetState(() => frequency = 'weekly'),
                      selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: frequency == 'weekly' ? AppColors.childGreen : AppColors.textSecondary,
                        fontWeight: frequency == 'weekly' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Mensal'),
                      selected: frequency == 'monthly',
                      onSelected: (_) => setSheetState(() => frequency = 'monthly'),
                      selectedColor: AppColors.childGreen.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: frequency == 'monthly' ? AppColors.childGreen : AppColors.textSecondary,
                        fontWeight: frequency == 'monthly' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ChildService.updateChild(
                      childId: child.id,
                      allowanceAmount: double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0,
                      allowanceFrequency: frequency,
                    );
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.childGreen, foregroundColor: Colors.white),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClosePeriod(Child child) {
    final periodStart = child.periodStartDate ?? DateTime.now().subtract(Duration(days: _periodDays(child.allowanceFrequency)));
    final periodEnd = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Fechar Periodo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child.hasPhoto
                ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(child.avatarUrl!))
                : Text(child.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Periodo', value: '${periodStart.day}/${periodStart.month} a ${periodEnd.day}/${periodEnd.month}'),
                  _InfoRow(label: 'Frequencia', value: _frequencyLabel(child.allowanceFrequency)),
                  _InfoRow(label: 'Mesada', value: 'R\$ ${child.allowanceAmount.toStringAsFixed(2)}'),
                  _InfoRow(label: 'Saldo atual', value: 'R\$ ${child.balance.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Isso vai registrar o fechamento do periodo atual e iniciar um novo.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
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
              await ChildService.resetPeriod(
                childId: child.id,
                familyId: widget.familyId,
                startDate: periodStart,
                endDate: periodEnd,
                frequency: child.allowanceFrequency,
                allowanceAmount: child.allowanceAmount,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Periodo fechado para ${child.name}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
            child: const Text('Fechar Periodo'),
          ),
        ],
      ),
    );
  }

  void _showHistory(Child child) async {
    final history = await ChildService.getPeriodHistory(child.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Historico de ${child.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('Nenhum periodo fechado ainda', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      itemBuilder: (ctx, index) {
                        final p = history[index];
                        final start = DateTime.parse(p['start_date']);
                        final end = DateTime.parse(p['end_date']);
                        return Container(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _frequencyLabel(p['frequency'] ?? 'weekly'),
                                      style: const TextStyle(fontSize: 10, color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _MiniStat(label: 'Mesada', value: 'R\$ ${(p['allowance_amount'] ?? 0).toStringAsFixed(2)}'),
                                  const SizedBox(width: 12),
                                  _MiniStat(label: 'Tarefas', value: '${p['tasks_completed'] ?? 0}/${p['tasks_total'] ?? 0}'),
                                  const SizedBox(width: 12),
                                  _MiniStat(label: 'Saldo', value: 'R\$ ${(p['final_balance'] ?? 0).toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildAllowanceCard extends StatelessWidget {
  final Child child;
  final VoidCallback onEdit;
  final VoidCallback onClosePeriod;
  final VoidCallback onViewHistory;

  const _ChildAllowanceCard({required this.child, required this.onEdit, required this.onClosePeriod, required this.onViewHistory});

  String _frequencyLabel(String freq) {
    switch (freq) {
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      default:
        return freq;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAllowance = child.allowanceAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              child.avatarWidget(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    if (hasAllowance)
                      Text(
                        'R\$ ${child.allowanceAmount.toStringAsFixed(2)} • ${_frequencyLabel(child.allowanceFrequency)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.childGreen, fontWeight: FontWeight.w600),
                      )
                    else
                      const Text('Mesada nao configurada', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Saldo', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('R\$ ${child.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.childGreen)),
                ],
              ),
            ],
          ),
          if (child.periodStartDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Periodo iniciou em ${child.periodStartDate!.day}/${child.periodStartDate!.month}/${child.periodStartDate!.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Configurar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.parentBlue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasAllowance ? onClosePeriod : null,
                  icon: const Icon(Icons.lock_clock, size: 16),
                  label: const Text('Fechar Periodo', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.history, color: AppColors.textSecondary),
                onPressed: onViewHistory,
                tooltip: 'Historico',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
