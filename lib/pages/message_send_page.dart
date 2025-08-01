import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../widgets/base_page.dart';

// Bu sayfa, kullanıcıların fısıltı (mesaj) göndermesini sağlar
class MessageSendPage extends StatefulWidget {
  const MessageSendPage({super.key});

  @override
  State<MessageSendPage> createState() => _MessageSendPageState();
}

class _MessageSendPageState extends State<MessageSendPage> {
  // "Kime" ve "mesaj" alanlarını kontrol eden TextEditingController'lar
  final TextEditingController toController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Mesaj gönderme işlemlerini yöneten servis
  final MessageService _messageService = MessageService();

  // Kullanıcı mesaj gönderdiğinde bu fonksiyon çalışır
  void sendMessage() async {
    final to = toController.text.trim(); // Kime gönderildiği (isteğe bağlı)
    final message = messageController.text.trim(); // Mesaj içeriği

    // Eğer mesaj boşsa kullanıcı uyarılır
    if (message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mesaj boş olamaz")),
      );
      return;
    }

    try {
      // Mesaj Firestore'a kaydedilir
      await _messageService.sendMessage(to: to, message: message);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mesaj gönderildi!")),
      );

      // Mesaj başarıyla gönderildiyse geri dönüş yapılır
      Navigator.pop(context);
    } catch (e) {
      // Hata durumunda kullanıcı bilgilendirilir
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gönderim hatası: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Yeni Fısıltı",
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // "Kime" alanı (isteğe bağlı)
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: "Kime? (opsiyonel)"),
            ),
            const SizedBox(height: 10),

            // Mesaj alanı
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Mesaj"),
            ),
            const SizedBox(height: 20),

            // Gönder butonu
            ElevatedButton(
              onPressed: sendMessage,
              child: const Text("Gönder"),
            ),
          ],
        ),
      ),
    );
  }
}
