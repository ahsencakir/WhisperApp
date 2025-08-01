import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// ✅ Girişte kullanıcı logu güncellenir
  static Future<void> updateLastLogin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;
    final displayName = FirebaseAuth.instance.currentUser?.displayName;


    if (uid == null || email == null) {
      print("❌ Kullanıcı bilgileri eksik.");
      return;
    }

    try {
      // ✅ 1. Supabase'de profil yoksa oluştur
      final profileExists = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();

      if (profileExists == null) {
        await _supabase.from('profiles').upsert({
          'id': uid,
          'email': email,
          'nickname': displayName ?? email,
        });
      }

      // ✅ 2. Giriş zamanını güncelle
      await _supabase.from('user_logs').upsert({
        'user_id': uid,
        'last_login': DateTime.now().toUtc().toIso8601String(),
      });

    } catch (e) {
      print("🔥 Login log error: $e");
    }
  }

  /// ✅ Kullanıcı çıkış yaptığında çıkış zamanı güncellenir
  static Future<void> updateLastLogout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("❌ Kullanıcı oturumu yok.");
      return;
    }

    try {
      final response = await _supabase.from('user_logs').upsert({
        'user_id': uid,
        'last_logout': DateTime.now().toUtc().toIso8601String(),
      }).select();
      print("✅ Last logout upserted: $response");
    } catch (e) {
      print("🔥 Logout log error: $e");
    }
  }

  static Future<void> updateMessageCount(int count) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final response = await _supabase.from('user_logs').upsert({
        'user_id': uid,
        'message_count': count,
      }).select();
    } catch (e) {
      print(" Supabase mesaj sayısı güncelleme hatası: $e");
    }
  }
}
