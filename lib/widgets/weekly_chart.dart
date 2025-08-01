import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

//  Haftalık mesaj sayılarını çubuk grafik olarak göstermek için kullanılan widget
class WeeklyChart extends StatelessWidget {
  final Map<String, int> data; // Tarih (gg.aa) ve o günkü mesaj sayısını tutar
  final double height;         // Grafik yüksekliğini özelleştirmek için

  const WeeklyChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    //  Tarihleri ters çevirerek (son gün en sağda olacak şekilde) listeye çevirir
    final items = data.entries.toList().reversed.toList();

    //  Veri yoksa kullanıcıya bilgi verir
    if (items.isEmpty) {
      return const Center(child: Text("Grafik verisi yok"));
    }

    return Card(
      elevation: 3, // Kartın gölgelendirmesi
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Köşeleri yuvarlatır
      margin: const EdgeInsets.only(bottom: 20), // Alt boşluk
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: height, // Grafik alanının yüksekliği
          child: BarChart(
            BarChartData(
              // 🔹 Her gün için bir çubuk oluşturur
              barGroups: items.asMap().entries.map((entry) {
                final index = entry.key; // X ekseni için index
                final value = entry.value.value.toDouble(); // Y ekseni için mesaj sayısı
                return BarChartGroupData(x: index, barRods: [
                  BarChartRodData(
                    toY: value,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.deepPurple,
                  ),
                ]);
              }).toList(),

              //  Eksen başlıklarını ayarlar
              titlesData: FlTitlesData(
                //  Sol eksen (mesaj sayıları)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),

                //  Alt eksen (tarih etiketleri)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= 0 && index < items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            items[index].key, // Tarihi yazdırır (örnek: 07.04)
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),

                //  Üst ve sağ eksenleri gizler
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              borderData: FlBorderData(show: false), // Kenar çizgilerini gizler
              gridData: FlGridData(show: true),      // Kılavuz çizgilerini gösterir

              //  En yüksek çubuğa göre maxY değerini belirler
              maxY: (data.values.isNotEmpty
                  ? data.values.reduce((a, b) => a > b ? a : b)
                  : 5)
                  .toDouble() +
                  1,
            ),
          ),
        ),
      ),
    );
  }
}
