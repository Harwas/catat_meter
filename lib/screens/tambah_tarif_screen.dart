import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahTarifScreen extends StatefulWidget {
  const TambahTarifScreen({Key? key}) : super(key: key);

  @override
  State<TambahTarifScreen> createState() => _TambahTarifScreenState();
}

class _TambahTarifScreenState extends State<TambahTarifScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  bool _loading = false;

  Future<void> _simpanTarif() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final namaTarif = _namaController.text.trim().toUpperCase();
    final harga = int.tryParse(_hargaController.text.trim()) ?? 0;

    if (namaTarif.isEmpty || harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tarif dan harga wajib diisi dengan benar')),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      // Simpan hanya field nama dan harga
      await FirebaseDatabase.instance.ref('tarif/$namaTarif').set({
        'nama': namaTarif,
        'harga': harga,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif berhasil ditambahkan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tarif: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Tarif')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Tarif'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama tarif wajib diisi' : null,
              ),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga per m³'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Harga wajib angka' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _simpanTarif,
                        child: const Text('Simpan'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}