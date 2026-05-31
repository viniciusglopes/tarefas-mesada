enum TaskStatus { pending, completed, approved, rejected }

class TaskTemplate {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final String icon;
  final int xpReward;
  final double moneyReward;
  final String frequency;
  final String? category;
  final String? assignedTo;
  final bool isActive;

  TaskTemplate({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    this.icon = '📋',
    this.xpReward = 10,
    this.moneyReward = 0,
    this.frequency = 'daily',
    this.category,
    this.assignedTo,
    this.isActive = true,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      familyId: json['family_id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? '📋',
      xpReward: json['xp_reward'] ?? 10,
      moneyReward: (json['money_reward'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? 'daily',
      category: json['category'],
      assignedTo: json['assigned_to'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'title': title,
    'description': description,
    'icon': icon,
    'xp_reward': xpReward,
    'money_reward': moneyReward,
    'frequency': frequency,
    'category': category,
    'assigned_to': assignedTo,
    'is_active': isActive,
  };
}

class Task {
  final String id;
  final String templateId;
  final String childId;
  final String familyId;
  final DateTime date;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? photoProofUrl;
  final TaskTemplate? template;

  Task({
    required this.id,
    required this.templateId,
    required this.childId,
    required this.familyId,
    required this.date,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.approvedAt,
    this.photoProofUrl,
    this.template,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      templateId: json['template_id'],
      childId: json['child_id'],
      familyId: json['family_id'],
      date: DateTime.parse(json['date']),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      photoProofUrl: json['photo_proof_url'],
      template: json['task_templates'] != null ? TaskTemplate.fromJson(json['task_templates']) : null,
    );
  }
}
