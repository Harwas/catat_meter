import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahCaterScreen extends StatefulWidget {
  const TambahCaterScreen({Key? key}) : super(key: key);

  @override
  State<TambahCaterScreen> createState() => _TambahCaterScreenState();
}

class _TambahCaterScreenState extends State<TambahCaterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodeCaterController = TextEditingController();
  final _namaCaterController = TextEditingController();
  bool _loading = false;

  Future<void> _simpanCater() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final kode = _kodeCaterController.text.trim();
    final nama = _namaCaterController.text.trim();

    final caterRef = FirebaseDatabase.instance.ref('cater').child(kode);
    await caterRef.set({
      'kode': kode,
      'nama': nama,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Cater berhasil ditambahkan!')));
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Catat Meter (Cater)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _kodeCaterController,
                decoration: const InputDecoration(labelText: 'Kode Cater'),
                validator: (v) => v == null || v.isEmpty ? 'Kode cater wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaCaterController,
                decoration: const InputDecoration(labelText: 'Nama Cater'),
                validator: (v) => v == null || v.isEmpty ? 'Nama cater wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _simpanCater,
                        child: const Text('Simpan Cater'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}