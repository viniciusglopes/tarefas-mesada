class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String tier;
  final int xpBonus;
  final String triggerType;
  final int triggerValue;
  final String? imageUrl;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.icon = '🏅',
    this.category = 'tasks',
    this.tier = 'bronze',
    this.xpBonus = 0,
    required this.triggerType,
    required this.triggerValue,
    this.imageUrl,
  });

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) {
    return BadgeDefinition(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      category: json['category'] ?? 'tasks',
      tier: json['tier'] ?? 'bronze',
      xpBonus: json['xp_bonus'] ?? 0,
      triggerType: json['trigger_type'],
      triggerValue: json['trigger_value'],
      imageUrl: json['image_url'],
    );
  }
}

class ChildBadge {
  final String id;
  final String childId;
  final String badgeId;
  final int progress;
  final DateTime? earnedAt;
  final BadgeDefinition? badge;

  ChildBadge({
    required this.id,
    required this.childId,
    required this.badgeId,
    this.progress = 0,
    this.earnedAt,
    this.badge,
  });

  bool get isEarned => earnedAt != null;

  double get progressPercent {
    if (badge == null) return 0;
    return (progress / badge!.triggerValue).clamp(0.0, 1.0);
  }

  factory ChildBadge.fromJson(Map<String, dynamic> json) {
    return ChildBadge(
      id: json['id'],
      childId: json['child_id'],
      badgeId: json['badge_id'],
      progress: json['progress'] ?? 0,
      earnedAt: json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
      badge: json['badge_definitions'] != null
          ? BadgeDefinition.fromJson(json['badge_definitions'])
          : null,
    );
  }
}
