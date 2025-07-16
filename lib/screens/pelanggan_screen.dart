import 'package:flutter/material.dart';

class PelangganScreen extends StatelessWidget {
  final List<Map<String, String>> pelangganList = [
    {
      'id': 'P001',
      'nama': 'Budi Santoso',
      'alamat': 'Jl. Melati No.10',
      'tarif': 'A1'
    },
    {
      'id': 'P002',
      'nama': 'Siti Aminah',
      'alamat': 'Jl. Mawar No.5',
      'tarif': 'B2'
    },
    {
      'id': 'P003',
      'nama': 'Andi Wijaya',
      'alamat': 'Jl. Kenanga No.3',
      'tarif': 'C1'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pelanggan'),
      ),
      body: ListView.builder(
        itemCount: pelangganList.length,
        itemBuilder: (context, index) {
          final pelanggan = pelangganList[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(child: Text(pelanggan['id']![1])),
              title: Text(pelanggan['nama'] ?? ''),
              subtitle: Text('${pelanggan['alamat']} • Tarif: ${pelanggan['tarif']}'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // aksi jika pelanggan diklik
              },
            ),
          );
        },
      ),
    );
  }
}
