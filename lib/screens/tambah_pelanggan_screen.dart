import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahPelangganScreen extends StatefulWidget {
  const TambahPelangganScreen({Key? key}) : super(key: key);

  @override
  State<TambahPelangganScreen> createState() => _TambahPelangganScreenState();
}

class _TambahPelangganScreenState extends State<TambahPelangganScreen> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final tanggalController = TextEditingController();
  final avatarController = TextEditingController();

  bool _loading = false;

  void _simpanPelanggan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final pelanggan = {
      'id': idController.text,
      'nama': namaController.text,
      'alamat': alamatController.text,
      'tanggal': tanggalController.text,
      'avatar': avatarController.text.isNotEmpty ? avatarController.text : '👤',
    };

    await FirebaseDatabase.instance
        .ref('pelanggan/${pelanggan['id']}')
        .set(pelanggan);

    setState(() => _loading = false);
    Navigator.pop(context, pelanggan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pelanggan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: idController,
                decoration: InputDecoration(labelText: 'ID'),
                validator: (v) => v == null || v.isEmpty ? 'ID wajib diisi' : null,
              ),
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: alamatController,
                decoration: InputDecoration(labelText: 'Padukuhan'),
                validator: (v) => v == null || v.isEmpty ? 'Padukuhan wajib diisi' : null,
              ),
              TextFormField(
                controller: tanggalController,
                decoration: InputDecoration(labelText: 'Tanggal (misal: 22 Juli 2025)'),
                validator: (v) => v == null || v.isEmpty ? 'Tanggal wajib diisi' : null,
              ),
              TextFormField(
                controller: avatarController,
                decoration: InputDecoration(labelText: 'Avatar (emoji, opsional)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _simpanPelanggan,
                icon: Icon(Icons.save),
                label: Text(_loading ? 'Menyimpan...' : 'Simpan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}