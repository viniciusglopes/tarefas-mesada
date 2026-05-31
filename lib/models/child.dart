class Child {
  final String id;
  final String familyId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String avatarType;
  final String? gender;
  final DateTime? birthDate;
  final int xp;
  final int level;
  final double balance;
  final int streak;
  final int bestStreak;
  final DateTime? lastTaskDate;

  Child({
    required this.id,
    required this.familyId,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.avatarType = 'emoji',
    this.gender,
    this.birthDate,
    this.xp = 0,
    this.level = 1,
    this.balance = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastTaskDate,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      familyId: json['family_id'],
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      avatarType: json['avatar_type'] ?? 'emoji',
      gender: json['gender'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      balance: (json['balance'] ?? 0).toDouble(),
      streak: json['streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      lastTaskDate: json['last_task_date'] != null ? DateTime.parse(json['last_task_date']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'name': name,
    'username': username,
    'avatar_url': avatarUrl,
    'avatar_type': avatarType,
    'gender': gender,
    'birth_date': birthDate?.toIso8601String().split('T').first,
  };
}
