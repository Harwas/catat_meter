import 'package:flutter/material.dart';
import 'detail_catatan_screen.dart';

class PencatatanScreen extends StatefulWidget {
  @override
  _PencatatanScreenState createState() => _PencatatanScreenState();
}

class _PencatatanScreenState extends State<PencatatanScreen> {
  List<Map<String, dynamic>> catatanList = [
    {
      'nama': 'Budi Santoso',
      'bulan': 'Juli 2025',
      'meter_awal': 120,
      'meter_akhir': 135,
      'tarif': 5000
    },
    {
      'nama': 'Siti Aminah',
      'bulan': 'Juli 2025',
      'meter_awal': 98,
      'meter_akhir': 112,
      'tarif': 5000
    },
    {
      'nama': 'Andi Wijaya',
      'bulan': 'Juli 2025',
      'meter_awal': 150,
      'meter_akhir': 172,
      'tarif': 5000
    },
  ];

  void _tambahCatatan() {
    final namaController = TextEditingController();
    final bulanController = TextEditingController();
    final meterAwalController = TextEditingController();
    final meterAkhirController = TextEditingController();
    final tarifController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah Catatan Meteran'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: namaController, decoration: InputDecoration(labelText: 'Nama')),
              TextField(controller: bulanController, decoration: InputDecoration(labelText: 'Bulan')),
              TextField(
                controller: meterAwalController,
                decoration: InputDecoration(labelText: 'Meter Awal'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: meterAkhirController,
                decoration: InputDecoration(labelText: 'Meter Akhir'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: tarifController,
                decoration: InputDecoration(labelText: 'Tarif per m³'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                catatanList.add({
                  'nama': namaController.text,
                  'bulan': bulanController.text,
                  'meter_awal': int.tryParse(meterAwalController.text) ?? 0,
                  'meter_akhir': int.tryParse(meterAkhirController.text) ?? 0,
                  'tarif': int.tryParse(tarifController.text) ?? 0,
                });
              });
              Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailCatatanScreen(catatan: catat),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahCatatan,
        child: Icon(Icons.add),
      ),
    );
  }
}
