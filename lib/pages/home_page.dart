import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/base_page.dart';
import '../services/log_service.dart';


// Ana ekranı tanımlar
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı bilgilerini ve istatistikleri tutar
  String nickname = "";
  int userMessageCount = 0;
  int totalMessageCount = 0;
  String lastMessage = "";
  String mostMessagedTo = "";
  Map<String, int> last7DaysStats = {};

  @override
  void initState() {
    super.initState();

    // Dashboard verilerini yükle (mesaj sayısı sonra loglanacak)
    _loadDashboardInfo();

  }


  // Dashboard verilerini yükler
  Future<void> _loadDashboardInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Kullanıcının nickname'ini alır
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    nickname = userData?['nickname'] ?? user.email ?? "Kullanıcı";

    // Sistemdeki toplam mesaj sayısını alır
    final allMessages = await _firestore.collection('messages').get();
    totalMessageCount = allMessages.docs.length;

    // Kullanıcının mesajlarını alır
    final userMessagesQuery = await _firestore
        .collection('messages')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    final userMessages = userMessagesQuery.docs;
    userMessageCount = userMessages.length;

    // Son mesajı alır
    if (userMessages.isNotEmpty) {
      lastMessage = userMessages.first.data()['message'] ?? "";
    }

    // En çok mesaj gönderilen kişiyi belirler
    final toCounts = <String, int>{};
    for (var doc in userMessages) {
      final to = doc.data()['to'] ?? 'Anonim';
      toCounts[to] = (toCounts[to] ?? 0) + 1;
    }

    if (toCounts.isNotEmpty) {
      final sorted = toCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostMessagedTo = sorted.first.key;
    }

    // Son 7 güne ait istatistikleri hazırlar
    final now = DateTime.now();
    last7DaysStats = {
      for (int i = 0; i < 7; i++)
        _formatDate(now.subtract(Duration(days: i))): 0,
    };

    // Her bir mesajın tarihine göre 7 günlük istatistikleri günceller
    for (var doc in userMessages) {
      final ts = doc.data()['timestamp'];
      if (ts is Timestamp) {
        final date = ts.toDate();
        final formatted = _formatDate(date);
        if (last7DaysStats.containsKey(formatted)) {
          last7DaysStats[formatted] = last7DaysStats[formatted]! + 1;
        }
      }
    }

    setState(() {}); // Ekranı günceller
    await LogService.updateMessageCount(userMessageCount);
  }

  // Tarihi dd.MM formatında döndürür
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          _loadDashboardInfo(); // Veriler güncel ise tekrar bilgileri çeker
        }

        return BasePage(
          title: "Ana Sayfa",
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                const Text("Merhaba 👋", style: TextStyle(fontSize: 26)),
                const SizedBox(height: 8),
                Text(nickname,
                    style: const TextStyle(fontSize: 18, color: Colors.grey)),
                const Divider(height: 40),
                // Kullanıcıya ait istatistikleri gösterir
                Text("📩 Toplam fısıltı sayın: $userMessageCount",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("🌍 Toplulukta toplam $totalMessageCount fısıltı var",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  lastMessage.isNotEmpty
                      ? "📝 Son fısıltın: \"$lastMessage\""
                      : "📝 Henüz fısıltın atmadın.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (mostMessagedTo.isNotEmpty)
                  Text("📬 En çok fısıltı gönderdiğin kişi: $mostMessagedTo",
                      style: const TextStyle(fontSize: 16)),
                const Divider(height: 40),
                const Text("📊 Son 7 Günlük Aktiviten:",
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                // Haftalık grafik gösterimi
                SizedBox(height: 250, child: WeeklyChart(data: last7DaysStats)),
                const SizedBox(height: 30),
                // Yeni mesaj gönderme butonu
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Yeni Fısıltı"),
                  onPressed: () => Navigator.pushNamed(context, '/send'),
                ),
                const SizedBox(height: 12),
                // Mesaj akışına yönlendirme butonu
                OutlinedButton.icon(
                  icon: const Icon(Icons.forum),
                  label: const Text("Fısıltılar"),
                  onPressed: () => Navigator.pushNamed(context, '/feed'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
