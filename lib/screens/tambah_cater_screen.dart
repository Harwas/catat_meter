import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahCaterScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Tambah parameter user

  const TambahCaterScreen({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<TambahCaterScreen> createState() => _TambahCaterScreenState();
}

class _TambahCaterScreenState extends State<TambahCaterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodeCaterController = TextEditingController();
  final _namaCaterController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _simpanCater() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final kode = _kodeCaterController.text.trim();
    final nama = _namaCaterController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final caterRef = FirebaseDatabase.instance.ref('cater').child(kode);
    final usersRef = FirebaseDatabase.instance.ref('users');

    // Simpan cater
    await caterRef.set({
      'kode': kode,
      'nama': nama,
      'created_at': DateTime.now().toIso8601String(),
      'dibuat_oleh': widget.currentUser['username'],
      'dibuat_oleh_uid': widget.currentUser['uid'],
      'dibuat_oleh_role': widget.currentUser['role'],
    });

    // Cari ID user terakhir (asumsi: key numerik bertambah)
    final usersSnapshot = await usersRef.get();
    int lastId = 0;
    if (usersSnapshot.exists) {
      for (var child in usersSnapshot.children) {
        final id = int.tryParse(child.key ?? '') ?? 0;
        if (id > lastId) lastId = id;
      }
    }
    final newUserId = (lastId + 1).toString();

    // Simpan user baru
    await usersRef.child(newUserId).set({
      'username': username,
      'password': password,
      'role': 'cater',
      'cater_kode': kode,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data Cater & User berhasil ditambahkan!'))
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
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
                      const SizedBox(height: 24),

                      // Input Username Cater
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username Cater',
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
                        validator: (v) => v == null || v.isEmpty ? 'Username cater wajib diisi' : null,
                      ),
                      const SizedBox(height: 24),

                      // Input Password Cater
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password Cater',
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
                        validator: (v) => v == null || v.isEmpty ? 'Password cater wajib diisi' : null,
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
      ),
    );
  }
}