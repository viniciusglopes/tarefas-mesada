import 'package:flutter/material.dart';

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
  final double allowanceAmount;
  final String allowanceFrequency;
  final DateTime? periodStartDate;

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
    this.allowanceAmount = 0,
    this.allowanceFrequency = 'weekly',
    this.periodStartDate,
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
      allowanceAmount: (json['allowance_amount'] ?? 0).toDouble(),
      allowanceFrequency: json['allowance_frequency'] ?? 'weekly',
      periodStartDate: json['period_start_date'] != null ? DateTime.parse(json['period_start_date']) : null,
    );
  }

  bool get hasPhoto => avatarUrl != null && avatarUrl!.startsWith('http');
  String get emoji => hasPhoto ? '🧒' : (avatarUrl ?? '🧒');

  Widget avatarWidget({double size = 24, double fontSize = 28}) {
    if (hasPhoto) {
      return CircleAvatar(
        radius: size,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: size,
      backgroundColor: const Color(0x1A4CAF50),
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
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
