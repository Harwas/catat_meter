import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditCaterScreen extends StatefulWidget {
  const EditCaterScreen({Key? key}) : super(key: key);

  @override
  State<EditCaterScreen> createState() => _EditCaterScreenState();
}

class _EditCaterScreenState extends State<EditCaterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  bool _loading = false;

  List<Map<String, dynamic>> _caterList = [];
  String? _selectedCaterKode;

  @override
  void initState() {
    super.initState();
    _fetchCater();
  }

  void _fetchCater() {
    FirebaseDatabase.instance.ref('cater').onValue.listen((event) {
      final snap = event.snapshot.value;
      if (snap != null) {
        final data = Map<String, dynamic>.from(snap as Map);
        setState(() {
          _caterList = data.entries.map((e) {
            final value = Map<String, dynamic>.from(e.value as Map);
            value['kode'] = value['kode'] ?? e.key as String;
            value['nama'] = value['nama'] ?? '';
            return value;
          }).toList();
        });
      }
    });
  }

  void _onCaterSelected(String? kode) {
    if (kode == null) return;
    final cater = _caterList.firstWhere((c) => c['kode'] == kode);
    _namaController.text = cater['nama'];
    _kodeController.text = cater['kode'];
    setState(() {
      _selectedCaterKode = kode;
    });
  }

  Future<void> _updateCater() async {
    if (!_formKey.currentState!.validate() || _selectedCaterKode == null) return;
    setState(() => _loading = true);

    final namaBaru = _namaController.text.trim();
    final kodeBaru = _kodeController.text.trim().toUpperCase();

    try {
      await FirebaseDatabase.instance.ref('cater/$_selectedCaterKode').update({
        'nama': namaBaru,
        'kode': kodeBaru,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cater berhasil diupdate!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst); // Kembali ke home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update cater: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Cater')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCaterKode,
                items: _caterList.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['kode'],
                    child: Text('${c['kode']} - ${c['nama']}'),
                  );
                }).toList(),
                onChanged: _onCaterSelected,
                decoration: const InputDecoration(labelText: 'Pilih Cater untuk Diedit'),
                validator: (v) => v == null ? 'Pilih cater terlebih dahulu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kodeController,
                decoration: const InputDecoration(labelText: 'Kode Cater'),
                style: const TextStyle(fontSize: 20),
                validator: (v) => v == null || v.trim().isEmpty ? 'Kode cater wajib diisi' : null,
              ),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Cater'),
                style: const TextStyle(fontSize: 20),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama cater wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateCater,
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