import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahPelangganScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const TambahPelangganScreen({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<TambahPelangganScreen> createState() => _TambahPelangganScreenState();
}

class _TambahPelangganScreenState extends State<TambahPelangganScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _telponController = TextEditingController();
  final TextEditingController _koordinatController = TextEditingController();
  DateTime? _tanggalSambung;

  List<Map<String, dynamic>> _caterList = [];
  List<Map<String, dynamic>> _tarifList = [];
  String? _selectedCaterKode;
  String? _selectedTarifKey;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchCater();
    _fetchTarif();

    // Jika role cater, otomatis pilih cater sesuai user & disable dropdown cater
    if (widget.currentUser['role'] == 'cater') {
      _selectedCaterKode = widget.currentUser['cater_kode'];
    }
  }

  void _fetchCater() {
    FirebaseDatabase.instance.ref('cater').onValue.listen((event) {
      final snap = event.snapshot.value;
      if (snap != null) {
        final data = Map<String, dynamic>.from(snap as Map);
        setState(() {
          _caterList = data.entries.map((e) {
            final value = Map<String, dynamic>.from(e.value as Map);
            value['key'] = e.key as String;
            value['kode'] = value['kode'] ?? e.key as String;
            value['nama'] = value['nama'] ?? '';
            return value;
          }).toList();
        });
      } else {
        setState(() {
          _caterList = [];
        });
      }
    });
  }

  void _fetchTarif() {
    FirebaseDatabase.instance.ref('tarif').onValue.listen((event) {
      final snap = event.snapshot.value;
      if (snap != null) {
        final data = Map<String, dynamic>.from(snap as Map);
        setState(() {
          _tarifList = data.entries.map((e) {
            final value = Map<String, dynamic>.from(e.value as Map);
            value['key'] = e.key as String;
            value['nama'] = value['nama'] ?? '';
            value['harga'] = value['harga'] ?? 0;
            return value;
          }).toList();
        });
      } else {
        setState(() {
          _tarifList = [];
        });
      }
    });
  }

  Future<String> _generatePelangganId(String caterKode, String tarifNama) async {
    final ref = FirebaseDatabase.instance.ref('pelanggan');
    final snapshot = await ref.get();
    int maxUrut = 0;
    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      for (final p in data.values) {
        final pelanggan = Map<dynamic, dynamic>.from(p);
        if (pelanggan['id'] != null &&
            pelanggan['id'] is String &&
            (pelanggan['id'] as String).startsWith(tarifNama) &&
            (pelanggan['id'] as String).endsWith(caterKode)) {
          final id = pelanggan['id'] as String;
          final numberPart = id.substring(tarifNama.length, id.length - caterKode.length);
          final urut = int.tryParse(numberPart) ?? 0;
          if (urut > maxUrut) maxUrut = urut;
        }
      }
    }
    final nextUrut = (maxUrut + 1).toString().padLeft(4, '0');
    return "$tarifNama$nextUrut$caterKode";
  }

  Future<void> _simpanPelanggan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaterKode == null || _selectedTarifKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cater dan tarif wajib dipilih')),
      );
      return;
    }
    if (_tanggalSambung == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal sambung wajib dipilih')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final nama = _namaController.text.trim();
      final selectedCater = _caterList.firstWhere((c) => c['kode'] == _selectedCaterKode);
      final selectedTarif = _tarifList.firstWhere((t) => t['key'] == _selectedTarifKey);

      final id = await _generatePelangganId(selectedCater['kode'], selectedTarif['nama']);
      await FirebaseDatabase.instance.ref('pelanggan/$id').set({
        'id': id,
        'nama': nama,
        'alamat': _alamatController.text.trim(),
        'telpon': _telponController.text.trim(),
        'tanggal_sambung': _tanggalSambung?.toIso8601String(),
        'koordinat': _koordinatController.text.trim(),
        'cater_kode': selectedCater['kode'],
        'cater_nama': selectedCater['nama'],
        'tarif_key': selectedTarif['key'],
        'tarif_nama': selectedTarif['nama'],
        'harga_per_m3': selectedTarif['harga'],
        'stand_awal': 0,
        'stand_baru': 0,
        'kubikasi': 0,
        'terhutang': 0,
        'tanggal_catat': DateTime.now().toIso8601String(),
        'dibuat_oleh': widget.currentUser['username'],
        'dibuat_oleh_uid': widget.currentUser['uid'],
        'dibuat_oleh_role': widget.currentUser['role'],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelanggan berhasil ditambahkan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pelanggan: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickTanggalSambung(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalSambung ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _tanggalSambung = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header biru dengan judul
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    // Tombol back
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'TAMBAH PELANGGAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Logo/Icon di kanan
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
            ),
          ),
          // Content area dengan card
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF2196F3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: EdgeInsets.all(24),
                          children: [
                            // ID Pelanggan Preview
                            if (_selectedCaterKode != null && _selectedTarifKey != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 20),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Pelanggan (Otomatis)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    FutureBuilder<String>(
                                      future: () {
                                        final selectedCater = _caterList.firstWhere(
                                            (c) => c['kode'] == _selectedCaterKode,
                                            orElse: () => {});
                                        final selectedTarif = _tarifList.firstWhere(
                                            (t) => t['key'] == _selectedTarifKey,
                                            orElse: () => {});
                                        if (selectedCater.isEmpty || selectedTarif.isEmpty) {
                                          return Future.value('-');
                                        }
                                        return _generatePelangganId(
                                            selectedCater['kode'], selectedTarif['nama']);
                                      }(),
                                      builder: (context, snapshot) => Text(
                                        snapshot.data ?? '-',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Nama Pelanggan
                            _buildCustomTextField(
                              controller: _namaController,
                              label: 'Nama Pelanggan',
                              validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                            ),
                            SizedBox(height: 20),
                            // Alamat
                            _buildCustomTextField(
                              controller: _alamatController,
                              label: 'Alamat',
                              validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                            ),
                            SizedBox(height: 20),
                            // No Telepon
                            _buildCustomTextField(
                              controller: _telponController,
                              label: 'No Telepon',
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? 'No telpon wajib diisi' : null,
                            ),
                            SizedBox(height: 20),
                            // Tanggal Sambung
                            InkWell(
                              onTap: () => _pickTanggalSambung(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.yellow, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal Sambung',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _tanggalSambung != null
                                              ? "${_tanggalSambung!.day}/${_tanggalSambung!.month}/${_tanggalSambung!.year}"
                                              : 'Pilih Tanggal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _tanggalSambung == null ? Colors.grey[400] : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.calendar_today, color: Color(0xFF2196F3), size: 20),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Koordinat
                            _buildCustomTextField(
                              controller: _koordinatController,
                              label: 'Koordinat',
                              validator: (v) => v == null || v.isEmpty ? 'Koordinat wajib diisi' : null,
                            ),
                            SizedBox(height: 20),
                            // Cater
                            _buildCustomDropdown<String>(
                              value: _selectedCaterKode,
                              label: 'Cater',
                              items: _caterList.map((c) {
                                final kode = c['kode'] as String;
                                final nama = c['nama'] ?? '';
                                return DropdownMenuItem<String>(
                                  value: kode,
                                  child: Text("$kode - $nama"),
                                );
                              }).toList(),
                              onChanged: (widget.currentUser['role'] == 'cater')
                                  ? null
                                  : (v) => setState(() => _selectedCaterKode = v),
                              validator: (v) => v == null ? 'Cater wajib dipilih' : null,
                            ),
                            SizedBox(height: 20),
                            // Tarif
                            _buildCustomDropdown<String>(
                              value: _selectedTarifKey,
                              label: 'Tarif',
                              items: _tarifList.map((t) {
                                final key = t['key'] as String;
                                final nama = t['nama'] ?? '';
                                final harga = t['harga'] ?? '';
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text("$nama (Rp $harga/m³)"),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedTarifKey = v),
                              validator: (v) => v == null ? 'Tarif wajib dipilih' : null,
                            ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    // Tombol Simpan
                    Container(
                      padding: EdgeInsets.all(24),
                      child: _loading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _simpanPelanggan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'SIMPAN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2196F3),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2196F3),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            suffixIcon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF2196F3)),
          ),
        ),
      ],
    );
  }
}