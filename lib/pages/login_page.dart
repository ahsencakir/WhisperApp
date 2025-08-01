import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

// Giriş ekranını temsil eden StatefulWidget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService(); // Yetkilendirme servisini çağırır
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase kimlik doğrulamasına erişir
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore erişimi sağlar

  final TextEditingController emailController = TextEditingController(); // Email alanı için controller
  final TextEditingController passwordController = TextEditingController(); // Şifre alanı için controller

  // Giriş işlemini gerçekleştirir
  void login() async {
    final email = emailController.text.trim(); // Email girdisini alır
    final password = passwordController.text.trim(); // Şifre girdisini alır

    String? error = await _authService.loginUser(email, password); // Giriş yapmayı dener

    if (!mounted) return; // Widget hala bağlanmamışsa çıkış yapar

    if (error == null) {
      User? user = _auth.currentUser; // Mevcut kullanıcıyı alır
      if (user != null) {
        await _checkUserProfile(user); // Kullanıcı profili varsa kontrol eder, yoksa oluşturur
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home'); // Anasayfaya yönlendirir
    } else {
      // Hata varsa kullanıcıya gösterir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  // Kullanıcının Firestore'da profili olup olmadığını kontrol eder, yoksa oluşturur
  Future<void> _checkUserProfile(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'nickname': user.email, // İlk başta eposta ile aynı olacak şekilde nickname belirlenir
        'createdAt': FieldValue.serverTimestamp(), // Oluşturulma zamanı eklenir
      });
    }
  }

  // Şifre sıfırlama diyaloğunu gösterir
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırla'),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(labelText: 'Email Adresiniz'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                String? error = await _authService.sendPasswordResetEmail(email);
                if (!mounted) return;
                Navigator.pop(context); // Diyaloğu kapat
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Şifre sıfırlama e-postası gönderildi. E-postanızı kontrol edin.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Şifre sıfırlama hatası: $error")),
                  );
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen email adresinizi girin.")),
                );
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.themeMode == ThemeMode.dark ||
        (themeService.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Logo için tema moduna göre doğru yolu seç
    final googleLogoPath = isDarkMode
        ? 'assets/logos/dark/google_dark.png'
        : 'assets/logos/light/google_white.png';
    final githubLogoPath = isDarkMode
        ? 'assets/logos/dark/github-mark_dark.png'
        : 'assets/logos/light/github-mark-white.png';

    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                const Text(
                  "Whisper",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // Email giriş alanı
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                // Şifre giriş alanı
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Şifre"),
                ),
                const SizedBox(height: 20),
                // Giriş yap butonu
                ElevatedButton(
                  onPressed: login,
                  child: const Text("Giriş Yap"),
                ),
                const SizedBox(height: 10),
                // Google ile giriş butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset(googleLogoPath, height: 24.0),
                    label: const Text('Google ile Giriş Yap', overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    onPressed: () async {
                      String? error = await _authService.signInWithGoogle();
                      if (!mounted) return;
                      if (error == null) {
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // GitHub ile giriş butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset(githubLogoPath, height: 24.0, color: isDarkMode ? null : Colors.white,),
                    label: const Text('GitHub ile Giriş Yap', overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    onPressed: () async {
                      String? error = await _authService.signInWithGitHub();
                      if (!mounted) return;
                      if (error == null) {
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Şifremi unuttum linki
                TextButton(
                  onPressed: () {
                    // Şifre sıfırlama diyaloğunu göster
                    _showForgotPasswordDialog(context);
                  },
                  child: const Text('Şifremi unuttum?'),
                ),
                // Kayıt ekranına yönlendiren buton
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text("Hesabın yok mu? Kayıt ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
