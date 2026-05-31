class PenaltyTemplate {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final String icon;
  final String? category;
  final String severity;
  final int xpDiscount;
  final double moneyDiscount;
  final bool isActive;

  PenaltyTemplate({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    this.icon = '⚠️',
    this.category,
    this.severity = 'light',
    this.xpDiscount = 0,
    this.moneyDiscount = 0,
    this.isActive = true,
  });

  factory PenaltyTemplate.fromJson(Map<String, dynamic> json) {
    return PenaltyTemplate(
      id: json['id'],
      familyId: json['family_id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? '⚠️',
      category: json['category'],
      severity: json['severity'] ?? 'light',
      xpDiscount: json['xp_discount'] ?? 0,
      moneyDiscount: (json['money_discount'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'title': title,
    'description': description,
    'icon': icon,
    'category': category,
    'severity': severity,
    'xp_discount': xpDiscount,
    'money_discount': moneyDiscount,
    'is_active': isActive,
  };
}

class Penalty {
  final String id;
  final String? templateId;
  final String childId;
  final String appliedBy;
  final String discountType;
  final int xpLost;
  final double moneyLost;
  final String? reason;
  final DateTime appliedAt;
  final PenaltyTemplate? template;

  Penalty({
    required this.id,
    this.templateId,
    required this.childId,
    required this.appliedBy,
    this.discountType = 'xp_and_money',
    this.xpLost = 0,
    this.moneyLost = 0,
    this.reason,
    required this.appliedAt,
    this.template,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      id: json['id'],
      templateId: json['template_id'],
      childId: json['child_id'],
      appliedBy: json['applied_by'],
      discountType: json['discount_type'] ?? 'xp_and_money',
      xpLost: json['xp_lost'] ?? 0,
      moneyLost: (json['money_lost'] ?? 0).toDouble(),
      reason: json['reason'],
      appliedAt: DateTime.parse(json['applied_at']),
      template: json['penalty_templates'] != null
          ? PenaltyTemplate.fromJson(json['penalty_templates'])
          : null,
    );
  }
}
