import 'package:flutter/material.dart';

class DetailPelangganScreen extends StatelessWidget {
  final Map<String, String> pelanggan;

  DetailPelangganScreen({required this.pelanggan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pelanggan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${pelanggan['id']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Nama: ${pelanggan['nama']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Alamat: ${pelanggan['alamat']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Tarif: ${pelanggan['tarif']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            // Tambahan lainnya seperti riwayat, grafik, dsb bisa ditambahkan di sini
          ],
        ),
      ),
    );
  }
}
