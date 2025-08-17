import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahTarifScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const TambahTarifScreen({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<TambahTarifScreen> createState() => _TambahTarifScreenState();
}

class _TambahTarifScreenState extends State<TambahTarifScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _abonemenController = TextEditingController();
  bool _loading = false;

  Future<void> _simpanTarif() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final namaTarif = _namaController.text.trim().toUpperCase();
    final harga = int.tryParse(_hargaController.text.trim()) ?? 0;
    final abonemen = int.tryParse(_abonemenController.text.trim()) ?? 0;

    if (namaTarif.isEmpty || harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tarif dan harga wajib diisi dengan benar')),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      await FirebaseDatabase.instance.ref('tarif/$namaTarif').set({
        'nama': namaTarif,
        'harga': harga,
        'abonemen': abonemen,
        'dibuat_oleh': widget.currentUser['username'],
        'dibuat_oleh_uid': widget.currentUser['uid'],
        'dibuat_oleh_role': widget.currentUser['role'],
        'tanggal_buat': DateTime.now().toIso8601String(),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'TAMBAH TARIF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEB3B),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/PROFIL.PNG',
                width: 35,
                height: 35,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A90E2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nama Tarif
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Tarif',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama tarif wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    // Harga
                    TextFormField(
                      controller: _hargaController,
                      decoration: InputDecoration(
                        labelText: 'Harga per m³',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Harga wajib angka' : null,
                    ),
                    const SizedBox(height: 24),

                    // Abonemen
                    TextFormField(
                      controller: _abonemenController,
                      decoration: InputDecoration(
                        labelText: 'Nominal Abonemen',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Abonemen wajib angka' : null,
                    ),
                    const SizedBox(height: 32),

                    // Tombol Simpan
                    _loading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _simpanTarif,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
