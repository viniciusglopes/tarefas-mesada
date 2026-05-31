class Reward {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final String icon;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isActive;

  Reward({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    this.icon = '🎁',
    required this.price,
    this.category = 'gifts',
    this.imageUrl,
    this.isActive = true,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      familyId: json['family_id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? '🎁',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'gifts',
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'title': title,
    'description': description,
    'icon': icon,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'is_active': isActive,
  };
}

class Redemption {
  final String id;
  final String childId;
  final String rewardId;
  final double pricePaid;
  final DateTime redeemedAt;
  final Reward? reward;

  Redemption({
    required this.id,
    required this.childId,
    required this.rewardId,
    required this.pricePaid,
    required this.redeemedAt,
    this.reward,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'],
      childId: json['child_id'],
      rewardId: json['reward_id'],
      pricePaid: (json['price_paid'] ?? 0).toDouble(),
      redeemedAt: DateTime.parse(json['redeemed_at']),
      reward: json['rewards'] != null ? Reward.fromJson(json['rewards']) : null,
    );
  }
}
