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

    if (authResponse.user != null) {
      final familyResult = await _client
          .from('families')
          .insert({'name': familyName})
          .select()
          .single();

      await _client.from('parents').insert({
        'id': authResponse.user!.id,
        'family_id': familyResult['id'],
        'name': name,
        'email': email,
      });
    }

    return authResponse;
  }

  static Future<AuthResponse> signInParent({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
}
