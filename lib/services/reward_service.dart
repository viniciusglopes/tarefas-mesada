import 'supabase_service.dart';
import '../models/reward.dart';

class RewardService {
  static final _client = SupabaseService.client;

  static Future<List<Reward>> getRewards(String familyId) async {
    final result = await _client
        .from('rewards')
        .select()
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('price');

    return (result as List).map((e) => Reward.fromJson(e)).toList();
  }

  static Future<void> createReward({
    required String familyId,
    required String title,
    String? description,
    String icon = '🎁',
    required double price,
    String category = 'gifts',
  }) async {
    await _client.from('rewards').insert({
      'family_id': familyId,
      'title': title,
      'description': description,
      'icon': icon,
      'price': price,
      'category': category,
    });
  }

  static Future<void> redeemReward({
    required String childId,
    required String rewardId,
    required double price,
  }) async {
    await _client.from('redemptions').insert({
      'child_id': childId,
      'reward_id': rewardId,
      'price_paid': price,
    });

    await _client.from('children').update({
      'balance': _client.rpc('', params: {}),
    });
  }

  static Future<bool> redeemWithBalanceCheck({
    required String childId,
    required String rewardId,
    required double price,
    required double currentBalance,
  }) async {
    if (currentBalance < price) return false;

    await _client.from('redemptions').insert({
      'child_id': childId,
      'reward_id': rewardId,
      'price_paid': price,
    });

    await _client.from('children').update({
      'balance': currentBalance - price,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', childId);

    return true;
  }

  static Future<List<Redemption>> getChildRedemptions(String childId) async {
    final result = await _client
        .from('redemptions')
        .select('*, rewards(*)')
        .eq('child_id', childId)
        .order('redeemed_at', ascending: false);

    return (result as List).map((e) => Redemption.fromJson(e)).toList();
  }

  static Future<void> deleteReward(String rewardId) async {
    await _client.from('rewards').update({'is_active': false}).eq('id', rewardId);
  }
}
