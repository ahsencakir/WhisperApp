import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whisper/services/auth_gate.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/message_send_page.dart';
import 'pages/profile_page.dart';
import 'pages/message_feed_page.dart';
import 'package:provider/provider.dart';
import 'package:whisper/services/theme_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/logo_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  final logoUrl = Supabase.instance.client
      .storage
      .from('whisper-png')
      .getPublicUrl('whisper-png.png');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) {
          final provider = LogoProvider();
          provider.fetchLogoFromApi(logoUrl);
          return provider;
        }),
      ],
      child: const MyApp(),
    ),
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Whisper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light, // Light theme
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark, // Dark theme
      ),
      themeMode: themeService.themeMode, // Tema modu ThemeService'dan alınır
      home: const AuthGate(), //  Otomatik yönlendirme burada
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/send': (_) => const MessageSendPage(),
        '/profile': (_) => const ProfilePage(),
        '/feed': (_) => const MessageFeedPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Turkish
      ],
    );
  }
}
