import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whisper/pages/home_page.dart';
import 'package:whisper/pages/login_page.dart';

import 'auth_service.dart';

// Bu widget, kullanıcının oturum durumuna göre yönlendirme yapar
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _handleAutoLogin();
  }

  Future<void> _handleAutoLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Kullanıcı oturum açmışsa local'e kaydet
      final authService = AuthService();
      await authService.saveUserDataLocally(user);
    }
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // FirebaseAuth üzerinden kullanıcı oturum değişikliklerini dinler
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı kurulurken yüklenme animasyonu gösterilir
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı oturum açmışsa ana sayfaya yönlendirir
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          // Oturum yoksa giriş ekranına yönlendirir
          return const LoginPage();
        }
      },
    );
  }
}
