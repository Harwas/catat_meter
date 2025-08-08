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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2196F3), // Blue background
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT TARIF',
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
            margin: EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.price_change,
              color: Color(0xFF2196F3),
              size: 24,
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
                // Dropdown untuk pilih tarif
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tarif untuk Di edit',
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
                        value: _selectedTarifKode,
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
                        items: _tarifList.map((t) {
                          return DropdownMenuItem<String>(
                            value: t['kode'],
                            child: Text('${t['nama']} (Rp ${t['harga']}/m³)'),
                          );
                        }).toList(),
                        onChanged: _onTarifSelected,
                        validator: (v) => v == null ? 'Pilih tarif terlebih dahulu' : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Input Nama Tarif
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Tarif',
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
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama tarif wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Input Harga per m³
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga per m³',
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
                        controller: _hargaController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Harga wajib angka' : null,
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
                            onPressed: _updateTarif,
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