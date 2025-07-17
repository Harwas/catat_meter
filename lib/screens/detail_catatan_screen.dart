import 'package:flutter/material.dart';

class DetailCatatanScreen extends StatelessWidget {
  final Map<String, dynamic> catatan;

  const DetailCatatanScreen({super.key, required this.catatan});

  @override
  Widget build(BuildContext context) {
    final int meterAwal = (catatan['meter_awal'] as num).toInt();
    final int meterAkhir = (catatan['meter_akhir'] as num).toInt();
    final int tarif = (catatan['tarif'] as num).toInt();
    final int pemakaian = meterAkhir - meterAwal;
    final int tagihan = pemakaian * tarif;


    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Catatan: ${catatan['nama']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nama: ${catatan['nama']}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Bulan: ${catatan['bulan']}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Meter Awal: $meterAwal', style: TextStyle(fontSize: 16)),
                Text('Meter Akhir: $meterAkhir', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Pemakaian: $pemakaian m³', style: TextStyle(fontSize: 16)),
                Text('Tarif per m³: Rp ${catatan['tarif']}', style: TextStyle(fontSize: 16)),
                Divider(height: 24),
                Text('Total Tagihan:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Rp $tagihan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
