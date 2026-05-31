class Level {
  final int level;
  final String nameMale;
  final String nameFemale;
  final int xpRequired;
  final String? cardImageUrl;
  final bool isPhysicalCard;

  Level({
    required this.level,
    required this.nameMale,
    required this.nameFemale,
    required this.xpRequired,
    this.cardImageUrl,
    this.isPhysicalCard = false,
  });

  String nameForGender(String? gender) =>
      gender == 'F' ? nameFemale : nameMale;

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      level: json['level'],
      nameMale: json['name_male'],
      nameFemale: json['name_female'],
      xpRequired: json['xp_required'],
      cardImageUrl: json['card_image_url'],
      isPhysicalCard: json['is_physical_card'] ?? false,
    );
  }
}
