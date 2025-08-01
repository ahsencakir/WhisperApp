import 'package:flutter/material.dart';

//  Her bir mesajı kart biçiminde göstermek için kullanılır
class MessageCard extends StatelessWidget {
  final String to;       // Mesajın gönderildiği kişi
  final String message;  // Mesaj içeriği
  final String date;     // Mesaj tarihi

  const MessageCard({
    super.key,
    required this.to,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // Kartın gölgesini belirler
      margin: const EdgeInsets.symmetric(vertical: 8), // Kartlar arası dikey boşluk
      child: ListTile(
        //  Mesaj içeriğini başlık olarak gösterir
        title: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),

        //  Alt bilgi olarak "Kime" ve tarih bilgilerini gösterir
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Kime: $to",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),

        isThreeLine: true, // Üç satırlık alan kullanılacağını belirtir
      ),
    );
  }
}
