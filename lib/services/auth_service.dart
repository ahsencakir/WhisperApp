import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart'; // ✅ BURASI ÖNEMLİ
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final fbAuth.FirebaseAuth _auth = fbAuth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Database? _database;

  Future<Database> _initDatabase() async {
    if (_database != null) return _database!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'user_data.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE user_data( uid TEXT PRIMARY KEY, email TEXT, first_name TEXT, last_name TEXT, nickname TEXT, birth_date TEXT, birth_place TEXT, city TEXT)'
        );
      },
    );
    return _database!;
  }

  Future<void> _saveToSharedPreferences(String uid, String email, String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    await prefs.setString('user_email', email);
    await prefs.setString('user_first_name', firstName);
    await prefs.setString('user_last_name', lastName);
  }

  Future<void> _saveToSqlite({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthDate,
    required String birthPlace,
    required String city,
  }) async {
    final db = await _initDatabase();
    await db.insert(
      'user_data',
      {
        'uid': uid,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birth_date': birthDate,
        'birth_place': birthPlace,
        'city': city,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> _fetchProfileFromSupabase(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('first_name, last_name, nickname')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print("Error fetching profile from Supabase: $e");
      return null;
    }
  }

  Future<void> saveUserDataLocally(fbAuth.User user) async {
    String uid = user.uid;
    String email = user.email ?? '';
    String firstName = '';
    String lastName = '';
    String nickname = '';
    String birthDate = '';
    String birthPlace = '';
    String city = '';

    final profileData = await _fetchProfileFromSupabase(uid);
    if (profileData != null) {
      firstName = profileData['first_name'] ?? '';
      lastName = profileData['last_name'] ?? '';
      nickname = profileData['nickname'] ?? '';
    }

    final firestoreDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final firestoreData = firestoreDoc.data();
    if (firestoreData != null) {
      birthDate = firestoreData['birth_date'] ?? '';
      birthPlace = firestoreData['birth_place'] ?? '';
      city = firestoreData['city'] ?? '';
    }

    await _saveToSharedPreferences(uid, email, firstName, lastName);
    await _saveToSqlite(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      birthDate: birthDate,
      birthPlace: birthPlace,
      city: city,
    );
  }

  Future<String?> registerUser(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'nickname': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _supabase.from('profiles').upsert({
          'id': user.uid,
          'email': user.email,
          'nickname': user.email,
        });

        await saveUserDataLocally(user);
        await LogService.updateLastLogin(); // ✅ Giriş sonrası login tarihi
      }

      return null;
    } on fbAuth.FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> loginUser(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = result.user;

      if (user != null) {
        await LogService.updateLastLogin(); // ✅ BURADA

        final profileExists = await _fetchProfileFromSupabase(user.uid) != null;
        if (!profileExists) {
          await _supabase.from('profiles').upsert({
            'id': user.uid,
            'email': user.email,
            'nickname': user.email,
          });
        }

        await saveUserDataLocally(user);
      }
      return null;
    } on fbAuth.FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logoutUser() async {
    await LogService.updateLastLogout(); // ✅ sadece logout zamanını kaydeder
    await _auth.signOut();
  }


  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth?.accessToken == null || googleAuth?.idToken == null) {
        return "Google oturum açma iptal edildi";
      }

      final credential = fbAuth.GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        await LogService.updateLastLogin(); // ✅ BURADA

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'nickname': user.displayName ?? user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final profileExists = await _fetchProfileFromSupabase(user.uid) != null;
        if (!profileExists) {
          final fullName = user.displayName ?? '';
          final parts = fullName.trim().split(' ');
          final firstName = parts.isNotEmpty ? parts.first : '';
          final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';



          await _supabase.from('profiles').upsert({
            'id': user.uid,
            'email': user.email,
            'nickname': fullName.isNotEmpty ? fullName : user.email,
            'first_name': firstName,
            'last_name': lastName,
          });
        }

        await saveUserDataLocally(user);
      }

      return null;
    } on fbAuth.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Google ile giriş yapılırken bir hata oluştu: ${e.toString()}";
    }
  }

  Future<String?> signInWithGitHub() async {
    try {
      final githubProvider = fbAuth.GithubAuthProvider();
      late fbAuth.UserCredential result;
      // Web ve mobil için uygun giriş yöntemini seç
      if (kIsWeb) {
        result = await _auth.signInWithPopup(githubProvider);
      } else {
        result = await _auth.signInWithProvider(githubProvider);
      }
      final user = result.user;

      if (user != null) {
        await LogService.updateLastLogin();

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'nickname': user.displayName ?? user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final profileExists = await _fetchProfileFromSupabase(user.uid) != null;
        if (!profileExists) {
          // 👇 Güvenli ad ve soyad ayrıştırma
          final fullName = (user.displayName ?? '').trim();
          final parts = fullName.split(' ');
          final firstName = parts.isNotEmpty ? parts.first : 'GitHub';
          final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'User';

          await _supabase.from('profiles').upsert({
            'id': user.uid,
            'email': user.email,
            'nickname': fullName.isNotEmpty ? fullName : user.email,
            'first_name': firstName,
            'last_name': lastName,
          });
        }

        await saveUserDataLocally(user);
      }

      return null;
    } on fbAuth.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "GitHub ile giriş yapılırken bir hata oluştu: \\${e.toString()}";
    }
  }


  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on fbAuth.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Şifre sıfırlama e-postası gönderilirken bir hata oluştu: ${e.toString()}";
    }
  }
}
