import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static late SharedPreferences _prefs;
  static const _childKey = 'child_session';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveChildSession(Map<String, dynamic> childData) async {
    await _prefs.setString(_childKey, jsonEncode(childData));
  }

  static Future<Map<String, dynamic>?> getChildSession() async {
    final data = _prefs.getString(_childKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> clearChildSession() async {
    await _prefs.remove(_childKey);
  }
}
