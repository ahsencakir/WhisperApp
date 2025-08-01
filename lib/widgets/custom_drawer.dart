import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../providers/logo_provider.dart';

//  Uygulamanın yan menüsünü (Drawer) oluşturur
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Eğer kullanıcı giriş yapmamışsa, Drawer boş bir mesaj döner
    if (user == null) {
      return const Drawer(
        child: Center(child: Text("Giriş yapılmamış")),
      );
    }

    //  Kullanıcının verilerini canlı olarak dinler
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String nickname = "Kullanıcı";

          // Veriler gelirse, nickname bilgisini gösterir
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            nickname = data?['nickname'] ?? user.email ?? "Anonim";
          }

          // Menü içeriği
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              //  Kullanıcı bilgilerini ve logo görselini gösteren üst alan
              UserAccountsDrawerHeader(
                accountName: const Text(""),
                accountEmail: Text(nickname),
                currentAccountPicture: Consumer<LogoProvider>(
                  builder: (context, logoProvider, _) {
                    final logoUrl = logoProvider.logoURL;

                    if (logoUrl == null || logoUrl.isEmpty) {
                      return const CircleAvatar(
                        child: Icon(Icons.person),
                      );
                    }

                    return CircleAvatar(
                      backgroundImage: NetworkImage(logoUrl),
                    );
                  },
                ),
                decoration: const BoxDecoration(color: Colors.deepPurple),
              ),

              // Ana Sayfaya yönlendiren menü
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Ana Sayfa"),
                onTap: () {
                  Navigator.pop(context); // Drawer'ı kapatır
                  Navigator.pushNamed(context, '/home'); // Ana sayfasına gider
                },
              ),

              //  Profil sayfasına yönlendiren menü
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profil"),
                onTap: () {
                  Navigator.pop(context); // Drawer'ı kapatır
                  Navigator.pushNamed(context, '/profile'); // Profil sayfasına gider
                },
              ),

              //  Fısıltı akışı sayfasına yönlendiren menü
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text("Fısıltılar"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/feed');
                },
              ),

              // Tema değiştirme menüsü
              ListTile(
                leading: const Icon(Icons.brightness_high),
                title: const Text("Tema Seç"),
                onTap: () {
                  _showThemePickerDialog(context);
                },
              ),

              //  Oturumu kapatır ve giriş sayfasına döner
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Çıkış Yap"),
                onTap: () async {
                  await AuthService().logoutUser();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (_) => false,
                    );
                  }
                },
              )],
          );
        },
      ),
    );}

  // Tema seçim diyaloğunu gösterir
  void _showThemePickerDialog(BuildContext context) {
    showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema Seçiniz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_low),
              title: const Text('Aydınlık'),
              onTap: () => Navigator.pop(context, ThemeMode.light),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_4),
              title: const Text('Karanlık'),
              onTap: () => Navigator.pop(context, ThemeMode.dark),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Sistem'),
              onTap: () => Navigator.pop(context, ThemeMode.system),
            ),
          ],
        ),
      ),
    ).then((selectedThemeMode) {
      if (selectedThemeMode != null) {
        Provider.of<ThemeService>(context, listen: false).setThemeMode(selectedThemeMode);
      }
    });
  }
}
