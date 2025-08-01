import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

// Bu sayfa, kullanıcıların yeni bir hesap oluşturmasını sağlar
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Kimlik doğrulama işlemleri için servis sınıfı
  final AuthService _authService = AuthService();

  // Kullanıcının girdiği e-posta ve şifreyi tutan kontrolcüler
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Kayıt işlemini başlatır
  void register() async {
    final email = emailController.text.trim(); // E-posta boşluklardan arındırılır
    final password = passwordController.text.trim(); // Şifre boşluklardan arındırılır

    // AuthService üzerinden kullanıcı kaydı yapılır
    String? error = await _authService.registerUser(email, password);

    if (!mounted) return; // Sayfa hala aktif mi kontrol edilir

    // Hata yoksa ana sayfaya yönlendirir
    if (error == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Hata varsa kullanıcıya gösterilir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
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

    // Arayüz bileşenleri tanımlanır
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Whisper", // Uygulama başlığı
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // E-posta giriş alanı
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
                // Kayıt olma butonu
                ElevatedButton(
                  onPressed: register,
                  child: const Text("Kayıt Ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
