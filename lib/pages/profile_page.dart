import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/base_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import
import 'package:intl/intl.dart'; // Date formatting
import 'package:flutter/foundation.dart' show kIsWeb;

// Bu sayfa, kullanıcının profil bilgilerini görüntülemesine ve kullanıcı adını değiştirmesine olanak tanır
// Yeni: Türkiye iller listesi
const List<String> turkishCities = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya',
  'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik',
  'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
  'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir',
  'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
  'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis',
  'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa',
  'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize',
  'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Sivas', 'Şırnak', 'Tekirdağ',
  'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak'
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Giriş yapan kullanıcıyı temsil eder
  final user = FirebaseAuth.instance.currentUser;

  // Kullanıcı adını düzenlemek için bir kontrolcü
  final TextEditingController nicknameController = TextEditingController();

  // Yeni: Doğum tarihi, doğum yeri ve il için kontrolcüler
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController birthplaceController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  // Yeni: Ad ve Soyad için kontrolcüler
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  // Firestore referansı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Supabase istemcisi
  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcının e-posta adresi ve kullanıcı adı
  String? email;
  String? currentNickname;

  // Yeni: Doğum tarihi, doğum yeri ve il bilgileri
  String? birthDate;
  String? birthplace;
  String? city;

  // Yeni: Ad ve Soyad bilgileri
  String? firstName;
  String? lastName;

  // Veriler yüklenirken gösterilecek yükleniyor durumu
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Sayfa açıldığında kullanıcı verisini getirir
  }

  // Controllerları temizle
  @override
  void dispose() {
    nicknameController.dispose();
    birthDateController.dispose();
    birthplaceController.dispose();
    cityController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  // Kullanıcının mevcut profil bilgilerini Firestore ve Supabase'den çeker
  Future<void> _loadUserProfile() async {
    try {
      // Firebase'den doğum tarihi, doğum yeri, il çek
      final firebaseDoc = await _firestore.collection('users').doc(user!.uid).get();
      final firebaseData = firebaseDoc.data();

      // Supabase'den ad, soyad, nickname çek
      // .single() yerine, kayıt yoksa null döndüren veya hatayı yakalayan bir yaklaşım kullanalım.
      // Supabase docs usually suggest catching the 0 rows error for .single()
      Map<String, dynamic>? supabaseData;
      try {
        supabaseData = await _supabase
            .from('profiles')
            .select('first_name, last_name, nickname')
            .eq('id', user!.uid)
            .single();
      } catch (e) {
        // Eğer hata 0 satır döndüğünü belirtiyorsa (PGRST116), supabaseData null kalır, bu beklenen bir durum.
        // Diğer hatalar loglanır.
        if (e is PostgrestException && e.code == 'PGRST116') {
          print("Supabase profile not found for user ${user!.uid}");
          supabaseData = null; // Profil yoksa null olarak işaretle
        } else {
          print("Unexpected Supabase error loading profile: $e");
          // Diğer beklenmeyen hatalar için kullanıcıya bilgi verilebilir veya farklı aksiyon alınabilir.
          // Şimdilik sadece loglayıp devam edelim.
        }
      }

      if (!mounted) return;

      // Verileri state içine atar ve kontrolcülere set eder
      setState(() {
        email = user?.email; // E-posta Firebase Auth'tan gelir

        // nickname'i Supabase'den al (Supabase öncelikli kaynak)
        currentNickname = supabaseData?['nickname'] ?? firebaseData?['nickname'] ?? "";
        nicknameController.text = currentNickname ?? "";

        // Firebase'den diğer bilgileri çek
        birthDate = firebaseData?['birth_date'] ?? "";
        birthplace = firebaseData?['birth_place'] ?? "";
        city = firebaseData?['city'] ?? "";

        birthDateController.text = birthDate ?? "";
        birthplaceController.text = birthplace ?? "";
        cityController.text = city ?? "";

        // Supabase'den ad ve soyad çek
        firstName = supabaseData?['first_name'] ?? "";
        lastName = supabaseData?['last_name'] ?? "";

        firstNameController.text = firstName ?? "";
        lastNameController.text = lastName ?? "";

        isLoading = false;
      });
    } catch (e, stacktrace) {
      if (!mounted) return;
      print("Error loading profile: $e\n$stacktrace"); // Log error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profil yüklenemedi: ${e.toString()}")),
      );
      setState(() { isLoading = false; }); // Stop loading even on error
    }
  }

  // Yeni: Doğum tarihi seçiciyi gösterir
  Future<void> _selectBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      // Seçilen tarihi Text alanına yazdır (gün.ay.yıl formatı)
      final formattedDate = DateFormat('dd.MM.yyyy').format(pickedDate);
      setState(() {
        birthDateController.text = formattedDate;
      });
    }
  }

  // Yeni: İl seçiciyi gösterir
  Future<void> _selectCity() async {
    final String? selectedCity = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İl Seçiniz'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: turkishCities.length,
              itemBuilder: (BuildContext context, int index) {
                final city = turkishCities[index];
                return ListTile(
                  title: Text(city),
                  onTap: () {
                    Navigator.of(context).pop(city);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedCity != null) {
      setState(() {
        cityController.text = selectedCity;
      });
    }
  }

  // Yeni: Tüm profil bilgilerini kaydeder (Firebase ve Supabase)
  Future<void> _saveProfile() async {
    final newNickname = nicknameController.text.trim();
    final newBirthDate = birthDateController.text.trim();
    final newBirthplace = birthplaceController.text.trim();
    final newCity = cityController.text.trim();
    final newFirstName = firstNameController.text.trim();
    final newLastName = lastNameController.text.trim();

    // Supabase'e kaydedilecek veriler (ad, soyad, nickname)
    final supabaseUpdates = {
      'id': user!.uid, // Kullanıcının Firebase UID'si Supabase ID olarak eklendi
      'first_name': newFirstName,
      'last_name': newLastName,
      'nickname': newNickname,
      'email': user?.email, // Add email to supabaseUpdates
    };

    // Firebase'e kaydedilecek veriler (doğum tarihi, doğum yeri, il)
    final firebaseUpdates = {
      'birth_date': newBirthDate,
      'birth_place': newBirthplace,
      'city': newCity,
      // nickname Firebase'de de vardı, Supabase ana kaynak olduğu için buradan kaldırılabilir
      // veya tutarlılık için burada da güncellenebilir. Şimdilik ikisinde de tutalım.
      'nickname': newNickname,
    };

    try {
      // Supabase güncellemesi (upsert kullanarak hem ekleme hem güncelleme yapabiliriz)
      await _supabase
          .from('profiles')
          .upsert(supabaseUpdates);

      // Firebase güncellemesi
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .set(firebaseUpdates, SetOptions(merge: true)); // merge: true existing fields update eder

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil bilgileri güncellendi!")),
      );

    } catch (e, stacktrace) {
      if (!mounted) return;
      print("Error saving profile: $e\n$stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme hatası: ${e.toString()}")),
      );
    }
  }

  // Provider bağlama fonksiyonları
  Future<void> _linkGoogleAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final googleProvider = GoogleAuthProvider();
    try {
      if (kIsWeb) {
        await user?.linkWithPopup(googleProvider);
      } else {
        await user?.linkWithProvider(googleProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google hesabı başarıyla bağlandı!")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'provider-already-linked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google hesabı zaten bağlı.")),
        );
      } else if (e.code == 'credential-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu Google hesabı başka bir kullanıcıya bağlı.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google bağlama hatası: \\${e.message}")),
        );
      }
    }
  }

  Future<void> _linkGitHubAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final githubProvider = GithubAuthProvider();
    try {
      if (kIsWeb) {
        await user?.linkWithPopup(githubProvider);
      } else {
        await user?.linkWithProvider(githubProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GitHub hesabı başarıyla bağlandı!")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'provider-already-linked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GitHub hesabı zaten bağlı.")),
        );
      } else if (e.code == 'credential-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu GitHub hesabı başka bir kullanıcıya bağlı.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("GitHub bağlama hatası: \\${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Veriler henüz yüklenmemişse yükleniyor göstergesi gösterilir
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Profil sayfası içeriği
    return BasePage(
      title: "Profil",
      body: SingleChildScrollView( // Add SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
          children: [
            const Center( // Center the profile icon
              child: Icon(Icons.person, size: 72, color: Colors.deepPurple), // Profil ikonu
            ),
            const SizedBox(height: 20),
            Center( // Center the email
              child: Text(
                email ?? "", // E-posta adresi gösterilir (değiştirilemez)
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),

            // Yeni: Ad alanı
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: "Ad"),
            ),
            const SizedBox(height: 20),
            // Yeni: Soyad alanı
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: "Soyad"),
            ),
            const SizedBox(height: 20),

            // Kullanıcı adı düzenleme alanı
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: "Kullanıcı Adı"),
            ),
            const SizedBox(height: 20),

            // Yeni: Doğum tarihi alanı (Takvim Seçici ile)
            TextField(
              controller: birthDateController,
              decoration: const InputDecoration(
                labelText: "Doğum Tarihi",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true, // Sadece takvim ile giriş
              onTap: _selectBirthDate, // Tıklayınca takvim açılsın
            ),
            const SizedBox(height: 20),

            // Yeni: Doğum yeri alanı
            TextField(
              controller: birthplaceController,
              decoration: const InputDecoration(labelText: "Doğum Yeri"),
            ),
            const SizedBox(height: 20),

            // Yeni: Yaşanılan il alanı (Şehir Seçici ile)
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: "Yaşadığı İl",
                suffixIcon: Icon(Icons.arrow_drop_down), // Dropdown iconu
              ),
              readOnly: true, // Sadece seçici ile giriş
              onTap: _selectCity, // Tıklayınca şehir seçici açılsın
            ),
            const SizedBox(height: 20),

            // Kaydet butonu
            Center( // Center the save button
              child: ElevatedButton(
                onPressed: _saveProfile, // Call the new save function
                child: const Text("Kaydet"),
              ),
            ),
            const SizedBox(height: 20),
            // Provider bağlama butonları
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text("Google Hesabını Bağla"),
                    onPressed: _linkGoogleAccount,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text("GitHub Hesabını Bağla"),
                    onPressed: _linkGitHubAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
