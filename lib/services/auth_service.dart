import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static final _client = SupabaseService.client;

  static Future<AuthResponse> signUpParent({
    required String email,
    required String password,
    required String name,
    required String familyName,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user != null && authResponse.session != null) {
      await _client.rpc('signup_parent', params: {
        'p_user_id': authResponse.user!.id,
        'p_name': name,
        'p_email': email,
        'p_family_name': familyName,
      });
    } else if (authResponse.user != null) {
      _pendingSignup = {
        'name': name,
        'email': email,
        'family_name': familyName,
      };
    }

    return authResponse;
  }

  static Map<String, String>? _pendingSignup;

  static Future<AuthResponse> signInParent({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user != null) {
      await _ensureParentExists(authResponse.user!.id, email);
    }

    return authResponse;
  }

  static Future<void> _ensureParentExists(String userId, String email) async {
    final existing = await _client
        .from('parents')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      final name = _pendingSignup?['name'] ?? email.split('@').first;
      final familyName = _pendingSignup?['family_name'] ?? 'Minha Familia';
      await _client.rpc('signup_parent', params: {
        'p_user_id': userId,
        'p_name': name,
        'p_email': email,
        'p_family_name': familyName,
      });
      _pendingSignup = null;
    }
  }

  static Future<Map<String, dynamic>?> signInChild({
    required String username,
    required String pin,
  }) async {
    final pinHash = sha256.convert(utf8.encode(pin)).toString();

    final result = await _client
        .from('children')
        .select()
        .eq('username', username)
        .eq('pin_hash', pinHash)
        .maybeSingle();

    return result;
  }

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> signOutChild() async {
    // Child sessions are handled by SessionService
  }
}
