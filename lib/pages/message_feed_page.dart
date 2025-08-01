import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/message_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/base_page.dart';

// Bu sayfa, sistemdeki tüm fısıltıları (mesajları) listeleyen akış sayfasıdır
class MessageFeedPage extends StatelessWidget {
  const MessageFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Fısıltı Akışı",
      body: Stack(
        children: [
          // Firestore'dan anlık veri akışı sağlar
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages') // "messages" koleksiyonunu alır
                .orderBy('timestamp', descending: true) // Yeni mesajları en üstte gösterir
                .snapshots(), // Anlık olarak değişiklikleri dinler
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Hata durumunda kullanıcıya bilgi verir
                return const Center(child: Text("Bir hata oluştu"));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                // Veri yüklenirken yükleniyor göstergesi sunar
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                // Hiç mesaj yoksa bilgi verir
                return const Center(child: Text("Henüz fısıltı yok"));
              }

              // Mesajları liste olarak gösterir
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>?;

                  if (data == null) return const SizedBox();

                  final to = data['to'] ?? "Anonim"; // Alıcı adı
                  final message = data['message'] ?? ""; // Mesaj içeriği
                  final timestamp = data['timestamp']; // Zaman bilgisi

                  String formattedDate = "Tarih yok";
                  if (timestamp is Timestamp) {
                    final date = timestamp.toDate(); // Timestamp'i DateTime'a çevirir
                    formattedDate =
                    "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} "
                        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  // Her mesajı özel MessageCard widget'ı ile gösterir
                  return MessageCard(
                    to: to,
                    message: message,
                    date: formattedDate,
                  );
                },
              );
            },
          ),
          // ✅ Fısıltı gönderme butonunu sayfanın altına ekler
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              tooltip: 'Fısıltı Gönder',
              onPressed: () {
                Navigator.pushNamed(context, '/send'); // Fısıltı gönderme sayfasına gider
              },
              child: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }
}
