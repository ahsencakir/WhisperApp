import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MessageService {
  final CollectionReference messagesRef =
  FirebaseFirestore.instance.collection('messages');

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔹 Yeni bir mesaj gönderir (Hem Firestore'a hem Supabase'e)
  Future<void> sendMessage({required String to, required String message}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Kullanıcı oturumu açık değil.");
    }

    // 1️⃣ Firestore'a mesaj gönder
    await messagesRef.add({
      'userId': user.uid,
      'to': to,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Supabase'e mesaj gönder (user_message_counts için)
    await _supabase.from('messages').insert({
      'sender_id': user.uid,
      'last_message': message,
    });
  }
}

