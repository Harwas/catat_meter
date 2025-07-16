import 'package:flutter/material.dart';

class PencatatanScreen extends StatelessWidget {
  final List<Map<String, dynamic>> catatanList = [
    {
      'nama': 'Budi Santoso',
      'bulan': 'Juli 2025',
      'meter_awal': 120,
      'meter_akhir': 135,
      'tarif': 2500
    },
    {
      'nama': 'Siti Aminah',
      'bulan': 'Juli 2025',
      'meter_awal': 98,
      'meter_akhir': 112,
      'tarif': 3000
    },
    {
      'nama': 'Andi Wijaya',
      'bulan': 'Juli 2025',
      'meter_awal': 150,
      'meter_akhir': 172,
      'tarif': 2800
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pencatatan Meteran')),
      body: ListView.builder(
        itemCount: catatanList.length,
        itemBuilder: (context, index) {
          final catat = catatanList[index];
          final pemakaian = catat['meter_akhir'] - catat['meter_awal'];
          final tagihan = pemakaian * catat['tarif'];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(catat['nama']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bulan: ${catat['bulan']}'),
                  Text('Meter Awal: ${catat['meter_awal']} | Akhir: ${catat['meter_akhir']}'),
                  Text('Pemakaian: $pemakaian m³'),
                ],
              ),
              trailing: Text('Rp $tagihan'),
            ),
          );
        },
      ),
    );
  }
}
