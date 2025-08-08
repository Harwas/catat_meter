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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data Cater berhasil ditambahkan!'))
    );
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3), // Biru sesuai desain
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TAMBAH CATAT METER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF7ED321), // Warna hijau untuk logo
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Card container sesuai desain
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
                    // Input Kode Cater
                    TextFormField(
                      controller: _kodeCaterController,
                      decoration: InputDecoration(
                        labelText: 'Kode Cater',
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
                      validator: (v) => v == null || v.isEmpty ? 'Kode cater wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Input Nama Cater
                    TextFormField(
                      controller: _namaCaterController,
                      decoration: InputDecoration(
                        labelText: 'Nama Cater',
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
                      validator: (v) => v == null || v.isEmpty ? 'Nama cater wajib diisi' : null,
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
                              onPressed: _simpanCater,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Simpan Cater',
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