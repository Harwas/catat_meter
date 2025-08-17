import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditPelangganScreen extends StatefulWidget {
  final String pelangganId;
  final Map pelangganData;
  const EditPelangganScreen({Key? key, required this.pelangganId, required this.pelangganData}) : super(key: key);

  @override
  State<EditPelangganScreen> createState() => _EditPelangganScreenState();
}

class _EditPelangganScreenState extends State<EditPelangganScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _telponController;
  late TextEditingController _tanggalSambungController;

  List<Map<String, dynamic>> _caterList = [];
  List<Map<String, dynamic>> _tarifList = [];
  String? _selectedCaterKode;
  String? _selectedTarifKey;
  bool _loading = false;
  bool _loadingDropdown = true;

  @override
  void initState() {
    super.initState();
    final data = widget.pelangganData;
    _namaController = TextEditingController(text: data['nama'] ?? "");
    _alamatController = TextEditingController(text: data['alamat'] ?? "");
    _telponController = TextEditingController(text: data['telpon'] ?? "");
    _tanggalSambungController = TextEditingController(
      text: (data['tanggal_sambung'] ?? "").toString().substring(0, 10),
    );
    _selectedCaterKode = data['cater_kode']?.toString();
    _selectedTarifKey = data['tarif_key']?.toString();
    _fetchDropdowns();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _telponController.dispose();
    _tanggalSambungController.dispose();
    super.dispose();
  }

  void _fetchDropdowns() async {
    setState(() => _loadingDropdown = true);
    // Fetch cater
    final caterSnap = await FirebaseDatabase.instance.ref('cater').get();
    final tarifSnap = await FirebaseDatabase.instance.ref('tarif').get();
    final List<Map<String, dynamic>> caterList = [];
    final List<Map<String, dynamic>> tarifList = [];

    if (caterSnap.exists) {
      final data = Map<String, dynamic>.from(caterSnap.value as Map);
      data.forEach((k, v) {
        final val = Map<String, dynamic>.from(v as Map);
        caterList.add({
          'kode': val['kode'] ?? k,
          'nama': val['nama'] ?? '',
        });
      });
    }
    if (tarifSnap.exists) {
      final data = Map<String, dynamic>.from(tarifSnap.value as Map);
      data.forEach((k, v) {
        final val = Map<String, dynamic>.from(v as Map);
        tarifList.add({
          'key': k,
          'nama': val['nama'] ?? '',
          'harga': val['harga'] ?? '',
        });
      });
    }
    setState(() {
      _caterList = caterList;
      _tarifList = tarifList;
      _loadingDropdown = false;
    });
  }

  Future<void> _simpanEdit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaterKode == null || _selectedTarifKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cater dan tarif wajib dipilih')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final selectedTarif = _tarifList.firstWhere((t) => t['key'] == _selectedTarifKey);
      final selectedCater = _caterList.firstWhere((c) => c['kode'] == _selectedCaterKode);

      final updateData = {
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'telpon': _telponController.text.trim(),
        'tanggal_sambung': _tanggalSambungController.text.trim(),
        'tarif_key': selectedTarif['key'],
        'tarif_nama': selectedTarif['nama'],
        'harga_per_m3': selectedTarif['harga'],
        'cater_kode': selectedCater['kode'],
        'cater_nama': selectedCater['nama'],
      };

      await FirebaseDatabase.instance.ref('pelanggan/${widget.pelangganId}').update(updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pelanggan berhasil diperbarui!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update data: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickTanggalSambung(BuildContext context) async {
    final now = DateTime.now();
    DateTime? current;
    try {
      if (_tanggalSambungController.text.isNotEmpty) {
        current = DateTime.parse(_tanggalSambungController.text);
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        _tanggalSambungController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF29A8F7),
        elevation: 0,
        title: const Text(
          "EDIT PELANGGAN",
          style: TextStyle(
            fontFamily: 'Comic Sans MS',
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingDropdown
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Color(0xFF29A8F7))),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _buildLabel("Nama Pelanggan"),
                          TextFormField(
                            controller: _namaController,
                            validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                            decoration: _inputDecoration("Nama pelanggan"),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("Alamat"),
                          TextFormField(
                            controller: _alamatController,
                            validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                            decoration: _inputDecoration("Alamat pelanggan"),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("No Telepon"),
                          TextFormField(
                            controller: _telponController,
                            validator: (v) => v == null || v.isEmpty ? 'No telepon wajib diisi' : null,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration("Nomor telepon"),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("Tanggal Sambung"),
                          InkWell(
                            onTap: () => _pickTanggalSambung(context),
                            child: IgnorePointer(
                              child: TextFormField(
                                controller: _tanggalSambungController,
                                decoration: _inputDecoration("yyyy-mm-dd"),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("Cater"),
                          DropdownButtonFormField<String>(
                            value: _selectedCaterKode,
                            items: _caterList.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['kode'],
                                child: Text('${c['kode']} - ${c['nama']}'),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCaterKode = v),
                            validator: (v) => v == null ? 'Cater wajib dipilih' : null,
                            decoration: _inputDecoration("Pilih cater"),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("Tarif"),
                          DropdownButtonFormField<String>(
                            value: _selectedTarifKey,
                            items: _tarifList.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['key'],
                                child: Text('${t['nama']} (Rp ${t['harga']}/m³)'),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedTarifKey = v),
                            validator: (v) => v == null ? 'Tarif wajib dipilih' : null,
                            decoration: _inputDecoration("Pilih tarif"),
                          ),
                          const SizedBox(height: 32),
                          _loading
                              ? Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF29A8F7),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onPressed: _simpanEdit,
                                  child: const Text("SIMPAN PERUBAHAN"),
                                ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Comic Sans MS',
        color: Color(0xFF29A8F7),
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 1,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF29A8F7).withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF29A8F7).withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF29A8F7), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}