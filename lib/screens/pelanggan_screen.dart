import 'package:flutter/material.dart';
import 'detail_pelanggan_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PelangganScreen extends StatefulWidget {
  @override
  _PelangganScreenState createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  List<Map<String, String>> pelangganList = [
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

  void _tambahPelanggan() {
    final idController = TextEditingController();
    final namaController = TextEditingController();
    final alamatController = TextEditingController();
    final tarifController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idController, decoration: InputDecoration(labelText: 'ID')),
              TextField(controller: namaController, decoration: InputDecoration(labelText: 'Nama')),
              TextField(controller: alamatController, decoration: InputDecoration(labelText: 'Alamat')),
              TextField(controller: tarifController, decoration: InputDecoration(labelText: 'Tarif')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                pelangganList.add({
                  'id': idController.text,
                  'nama': namaController.text,
                  'alamat': alamatController.text,
                  'tarif': tarifController.text,
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

  void _cetakPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Daftar Pelanggan', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            ...pelangganList.map(
              (pel) => pw.Text(
                  '${pel['id']} - ${pel['nama']} (${pel['tarif']})\n${pel['alamat']}'),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pelanggan'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _cetakPDF,
          ),
        ],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPelangganScreen(pelanggan: pelanggan),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahPelanggan,
        child: Icon(Icons.add),
      ),
    );
  }
}
