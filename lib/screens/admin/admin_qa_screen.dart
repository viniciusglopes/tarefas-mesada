import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';

class AdminQaScreen extends StatefulWidget {
  const AdminQaScreen({super.key});

  @override
  State<AdminQaScreen> createState() => _AdminQaScreenState();
}

class _TestResult {
  final String name;
  final String category;
  final bool passed;
  final String message;
  final Duration duration;

  _TestResult({required this.name, required this.category, required this.passed, required this.message, required this.duration});
}

class _AdminQaScreenState extends State<AdminQaScreen> {
  List<_TestResult> _results = [];
  bool _running = false;
  int _passed = 0;
  int _failed = 0;

  Future<void> _runAllTests() async {
    setState(() {
      _running = true;
      _results = [];
      _passed = 0;
      _failed = 0;
    });

    await _runTest('Conexao Supabase', 'Infra', () async {
      await SupabaseService.client.from('families').select('id').limit(1);
    });

    for (final table in ['families', 'parents', 'children', 'task_templates', 'tasks', 'badges', 'rewards', 'penalty_templates', 'messages', 'levels']) {
      await _runTest('Tabela $table', 'Banco', () async {
        await SupabaseService.client.from(table).select('id').limit(1);
      });
    }

    await _runTest('Auth usuario logado', 'Auth', () async {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Nenhum usuario logado');
    });

    await _runTest('Parent vinculado', 'Auth', () async {
      final userId = SupabaseService.currentUser!.id;
      final result = await SupabaseService.client.from('parents').select().eq('id', userId).maybeSingle();
      if (result == null) throw Exception('Parent nao encontrado para user $userId');
    });

    await _runTest('Family do parent', 'Dados', () async {
      final userId = SupabaseService.currentUser!.id;
      final parent = await SupabaseService.client.from('parents').select().eq('id', userId).single();
      final familyId = parent['family_id'];
      final family = await SupabaseService.client.from('families').select().eq('id', familyId).maybeSingle();
      if (family == null) throw Exception('Family $familyId nao encontrada');
    });

    await _runTest('RPC increment_child_rewards', 'Funcoes', () async {
      // Apenas verifica se a RPC existe (vai falhar se child nao existir, mas sem erro de funcao)
      try {
        await SupabaseService.client.rpc('increment_child_rewards', params: {
          'p_child_id': '00000000-0000-0000-0000-000000000000',
          'p_xp': 0,
          'p_money': 0,
        });
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('function') && msg.contains('does not exist')) rethrow;
      }
    });

    await _runTest('Join tasks + templates', 'Relacoes', () async {
      await SupabaseService.client
          .from('tasks')
          .select('id, task_templates(title)')
          .limit(1);
    });

    setState(() => _running = false);
  }

  Future<void> _runTest(String name, String category, Future<void> Function() test) async {
    final sw = Stopwatch()..start();
    try {
      await test();
      sw.stop();
      setState(() {
        _results.add(_TestResult(name: name, category: category, passed: true, message: 'OK', duration: sw.elapsed));
        _passed++;
      });
    } catch (e) {
      sw.stop();
      setState(() {
        _results.add(_TestResult(name: name, category: category, passed: false, message: e.toString(), duration: sw.elapsed));
        _failed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _passed + _failed;
    final pct = total > 0 ? (_passed / total * 100).toInt() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Testes QA'),
        automaticallyImplyLeading: false,
      ),
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
                if (total > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ResultBadge(value: '$_passed', label: 'Passou', color: AppColors.success),
                      _ResultBadge(value: '$_failed', label: 'Falhou', color: AppColors.danger),
                      _ResultBadge(value: '$pct%', label: 'Taxa', color: _failed == 0 ? AppColors.success : AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total > 0 ? _passed / total : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Clique para executar os testes', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runAllTests,
                    icon: _running
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.play_arrow),
                    label: Text(_running ? 'Executando...' : 'Executar Testes'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.xpPurple, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_results.isNotEmpty) ...[
            Text('Resultados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._results.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (r.passed ? AppColors.success : AppColors.danger).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (r.passed ? AppColors.success : AppColors.danger).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(r.passed ? Icons.check_circle : Icons.cancel, color: r.passed ? AppColors.success : AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(r.category, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 6),
                            Text('${r.duration.inMilliseconds}ms', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            if (!r.passed) ...[
                              const SizedBox(width: 6),
                              Flexible(child: Text(r.message, style: const TextStyle(fontSize: 10, color: AppColors.danger), overflow: TextOverflow.ellipsis)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultBadge({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
