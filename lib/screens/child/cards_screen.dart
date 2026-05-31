import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/child.dart';
import '../../models/level.dart';
import '../../services/supabase_service.dart';

class CardsScreen extends StatefulWidget {
  final Child child;
  const CardsScreen({super.key, required this.child});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Level> _levels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final result = await SupabaseService.client
        .from('levels')
        .select()
        .order('level');
    setState(() {
      _levels = (result as List).map((e) => Level.fromJson(e)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cartas de Nivel'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                final unlocked = widget.child.level >= level.level;
                final isCurrent = widget.child.level == level.level;

                return GestureDetector(
                  onTap: () => _showDetail(level, unlocked),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? AppColors.xpPurple : (unlocked ? AppColors.childGreen.withValues(alpha: 0.3) : AppColors.border),
                        width: isCurrent ? 3 : 1,
                      ),
                      color: unlocked ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
                      boxShadow: isCurrent ? [BoxShadow(color: AppColors.xpPurple.withValues(alpha: 0.2), blurRadius: 12)] : null,
                    ),
                    child: Opacity(
                      opacity: unlocked ? 1.0 : 0.4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.xpPurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('NIVEL ATUAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          Text(_cardEmoji(level.level), style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            level.nameForGender(widget.child.gender),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: unlocked ? AppColors.textPrimary : AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text('Nivel ${level.level}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (level.isPhysicalCard && unlocked)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('📮 Carta Fisica', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                            ),
                          if (!unlocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('${level.xpRequired} XP', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _cardEmoji(int level) {
    const emojis = ['🌱', '🗺️', '⚔️', '🛡️', '🏇', '🛡️', '⚜️', '🦸', '🌟', '👑'];
    return emojis[level - 1];
  }

  void _showDetail(Level level, bool unlocked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_cardEmoji(level.level), style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(level.nameForGender(widget.child.gender), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Nivel ${level.level} • ${level.xpRequired} XP necessarios', style: const TextStyle(color: AppColors.textSecondary)),
            if (level.isPhysicalCard) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Text('📮', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(child: Text('Este nivel desbloqueia uma carta FISICA enviada para sua casa!', style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!unlocked)
              Text('Faltam ${level.xpRequired - widget.child.xp} XP para desbloquear', style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
