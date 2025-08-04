import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditTarifScreen extends StatefulWidget {
  const EditTarifScreen({Key? key}) : super(key: key);

  @override
  State<EditTarifScreen> createState() => _EditTarifScreenState();
}

class _EditTarifScreenState extends State<EditTarifScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  bool _loading = false;

  List<Map<String, dynamic>> _tarifList = [];
  String? _selectedTarifKode;

  @override
  void initState() {
    super.initState();
    _fetchTarif();
  }

  void _fetchTarif() {
    FirebaseDatabase.instance.ref('tarif').onValue.listen((event) {
      final snap = event.snapshot.value;
      if (snap != null) {
        final data = Map<String, dynamic>.from(snap as Map);
        setState(() {
          _tarifList = data.entries.map((e) {
            final value = Map<String, dynamic>.from(e.value as Map);
            value['kode'] = e.key as String;
            value['nama'] = value['nama'] ?? '';
            value['harga'] = value['harga'] ?? 0;
            return value;
          }).toList();
        });
      }
    });
  }

  void _onTarifSelected(String? kode) {
    if (kode == null) return;
    final tarif = _tarifList.firstWhere((t) => t['kode'] == kode);
    _namaController.text = tarif['nama'];
    _hargaController.text = tarif['harga'].toString();
    setState(() {
      _selectedTarifKode = kode;
    });
  }

  Future<void> _updateTarif() async {
    if (!_formKey.currentState!.validate() || _selectedTarifKode == null) return;
    setState(() => _loading = true);

    final namaBaru = _namaController.text.trim().toUpperCase();
    final hargaBaru = int.tryParse(_hargaController.text.trim()) ?? 0;

    try {
      await FirebaseDatabase.instance.ref('tarif/$_selectedTarifKode').update({
        'nama': namaBaru,
        'harga': hargaBaru,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif berhasil diupdate!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst); // Kembali ke home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update tarif: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tarif')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTarifKode,
                items: _tarifList.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['kode'],
                    child: Text('${t['nama']} (Rp ${t['harga']}/m³)'),
                  );
                }).toList(),
                onChanged: _onTarifSelected,
                decoration: const InputDecoration(labelText: 'Pilih Tarif untuk Diedit'),
                validator: (v) => v == null ? 'Pilih tarif terlebih dahulu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Tarif'),
                style: const TextStyle(fontSize: 20),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama tarif wajib diisi' : null,
              ),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga per m³'),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Harga wajib angka' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateTarif,
                        child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 20)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}