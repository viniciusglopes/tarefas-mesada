import 'supabase_service.dart';
import '../models/penalty.dart';

class PenaltyService {
  static final _client = SupabaseService.client;

  static Future<List<PenaltyTemplate>> getTemplates(String familyId) async {
    final result = await _client
        .from('penalty_templates')
        .select()
        .eq('family_id', familyId)
        .eq('is_active', true)
        .order('severity');

    return (result as List).map((e) => PenaltyTemplate.fromJson(e)).toList();
  }

  static Future<void> createTemplate({
    required String familyId,
    required String title,
    String? description,
    String icon = '⚠️',
    String? category,
    String severity = 'light',
    int xpDiscount = 0,
    double moneyDiscount = 0,
  }) async {
    await _client.from('penalty_templates').insert({
      'family_id': familyId,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'severity': severity,
      'xp_discount': xpDiscount,
      'money_discount': moneyDiscount,
    });
  }

  static Future<void> updateTemplate({
    required String templateId,
    required String title,
    String icon = '⚠️',
    String severity = 'light',
    int xpDiscount = 0,
    double moneyDiscount = 0,
    String? category,
  }) async {
    await _client.from('penalty_templates').update({
      'title': title,
      'icon': icon,
      'severity': severity,
      'xp_discount': xpDiscount,
      'money_discount': moneyDiscount,
      'category': category,
    }).eq('id', templateId);
  }

  static Future<void> deleteTemplate(String templateId) async {
    await _client.from('penalty_templates').update({'is_active': false}).eq('id', templateId);
  }

  static Future<void> applyPenalty({
    required String childId,
    required String parentId,
    String? templateId,
    String discountType = 'xp_and_money',
    required int xpLost,
    required double moneyLost,
    String? reason,
  }) async {
    await _client.from('penalties').insert({
      'template_id': templateId,
      'child_id': childId,
      'applied_by': parentId,
      'discount_type': discountType,
      'xp_lost': xpLost,
      'money_lost': moneyLost,
      'reason': reason,
    });

    await _client.rpc('apply_penalty', params: {
      'p_child_id': childId,
      'p_xp': xpLost,
      'p_money': moneyLost,
    });
  }

  static Future<List<Penalty>> getChildPenalties(String childId) async {
    final result = await _client
        .from('penalties')
        .select('*, penalty_templates(*)')
        .eq('child_id', childId)
        .order('applied_at', ascending: false);

    return (result as List).map((e) => Penalty.fromJson(e)).toList();
  }
}
