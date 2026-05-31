import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/badge.dart';
import '../../models/child.dart';
import '../../services/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  final Child child;
  const BadgesScreen({super.key, required this.child});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<BadgeDefinition> _allBadges = [];
  List<ChildBadge> _childBadges = [];
  bool _loading = true;
  String _selectedCategory = 'all';

  static const _categories = {
    'all': 'Todas',
    'tasks': 'Tarefas',
    'speed': 'Velocidade',
    'streak': 'Sequencia',
    'special': 'Especiais',
    'social': 'Social',
  };

  static const _tierColors = {
    'bronze': Color(0xFFCD7F32),
    'silver': Color(0xFFC0C0C0),
    'gold': Color(0xFFFFD700),
    'diamond': Color(0xFFB9F2FF),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final badges = await BadgeService.getAllBadges();
    final childBadges = await BadgeService.getChildBadges(widget.child.id);
    setState(() {
      _allBadges = badges;
      _childBadges = childBadges;
      _loading = false;
    });
  }

  ChildBadge? _childBadgeFor(String badgeId) {
    try {
      return _childBadges.firstWhere((cb) => cb.badgeId == badgeId);
    } catch (_) {
      return null;
    }
  }

  List<BadgeDefinition> get _filteredBadges {
    if (_selectedCategory == 'all') return _allBadges;
    return _allBadges.where((b) => b.category == _selectedCategory).toList();
  }

  int get _earnedCount => _childBadges.where((cb) => cb.isEarned).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insignias'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '$_earnedCount/${_allBadges.length}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                      const SizedBox(width: 8),
                      const Text('conquistadas', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                          selectedColor: AppColors.warning.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.warning,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.warning : AppColors.textSecondary,
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _filteredBadges.length,
                    itemBuilder: (context, index) {
                      final badge = _filteredBadges[index];
                      final childBadge = _childBadgeFor(badge.id);
                      final earned = childBadge?.isEarned ?? false;
                      final progress = childBadge?.progress ?? 0;
                      final progressPercent = badge.triggerValue > 0
                          ? (progress / badge.triggerValue).clamp(0.0, 1.0)
                          : 0.0;

                      return GestureDetector(
                        onTap: () => _showDetail(badge, childBadge),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: earned
                                  ? (_tierColors[badge.tier] ?? AppColors.border)
                                  : AppColors.border,
                              width: earned ? 2 : 1,
                            ),
                            color: AppColors.surface,
                            boxShadow: earned
                                ? [BoxShadow(color: (_tierColors[badge.tier] ?? AppColors.warning).withValues(alpha: 0.15), blurRadius: 8)]
                                : null,
                          ),
                          child: Opacity(
                            opacity: earned ? 1.0 : 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(badge.icon, style: const TextStyle(fontSize: 36)),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    badge.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (_tierColors[badge.tier] ?? AppColors.border).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    badge.tier.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _tierColors[badge.tier] ?? AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (!earned) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: progressPercent,
                                        backgroundColor: AppColors.border,
                                        color: _tierColors[badge.tier] ?? AppColors.warning,
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showDetail(BadgeDefinition badge, ChildBadge? childBadge) {
    final earned = childBadge?.isEarned ?? false;
    final progress = childBadge?.progress ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(badge.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: (_tierColors[badge.tier] ?? AppColors.border).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge.tier.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _tierColors[badge.tier] ?? AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(badge.description, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (badge.xpBonus > 0)
              Text('+${badge.xpBonus} XP de bonus', style: const TextStyle(color: AppColors.xpPurple, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (earned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Conquistada!',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '$progress / ${badge.triggerValue}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: badge.triggerValue > 0 ? (progress / badge.triggerValue).clamp(0.0, 1.0) : 0,
                      backgroundColor: AppColors.border,
                      color: _tierColors[badge.tier] ?? AppColors.warning,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
