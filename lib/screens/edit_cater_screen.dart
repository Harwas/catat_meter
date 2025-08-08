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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2196F3), // Blue background
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT CATER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          // Logo/Icon placeholder (sesuai desain)
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
                // Menangani error jika gambar tidak ditemukan
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown untuk pilih cater
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Cater untuk Di edit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCaterKode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        items: _caterList.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['kode'],
                            child: Text('${c['kode']} - ${c['nama']}'),
                          );
                        }).toList(),
                        onChanged: _onCaterSelected,
                        validator: (v) => v == null ? 'Pilih cater terlebih dahulu' : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Input Kode Cater
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode Cater',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TextFormField(
                        controller: _kodeController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Kode cater wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Input Nama Cater
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Cater',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TextFormField(
                        controller: _namaController,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama cater wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextButton(
                            onPressed: _updateCater,
                            child: Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}