import 'supabase_service.dart';
import '../models/badge.dart';

class BadgeService {
  static final _client = SupabaseService.client;

  static Future<List<BadgeDefinition>> getAllBadges() async {
    final result = await _client
        .from('badge_definitions')
        .select()
        .order('category')
        .order('tier');

    return (result as List).map((e) => BadgeDefinition.fromJson(e)).toList();
  }

  static Future<List<ChildBadge>> getChildBadges(String childId) async {
    final result = await _client
        .from('child_badges')
        .select('*, badge_definitions(*)')
        .eq('child_id', childId);

    return (result as List).map((e) => ChildBadge.fromJson(e)).toList();
  }

  static Future<List<BadgeDefinition>> getBadgesByCategory(String category) async {
    final result = await _client
        .from('badge_definitions')
        .select()
        .eq('category', category)
        .order('tier');

    return (result as List).map((e) => BadgeDefinition.fromJson(e)).toList();
  }
}
