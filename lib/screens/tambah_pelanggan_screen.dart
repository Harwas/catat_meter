import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahPelangganScreen extends StatefulWidget {
  const TambahPelangganScreen({Key? key}) : super(key: key);

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
  }

  void _fetchCater() {
    FirebaseDatabase.instance.ref('cater').onValue.listen((event) {
      final snap = event.snapshot.value;
      if (snap != null) {
        final data = Map<String, dynamic>.from(snap as Map);
        setState(() {
          _caterList = data.entries.map((e) {
            final value = Map<String, dynamic>.from(e.value as Map);
            // Ambil kode dan nama cater dari database
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
            // Ambil key (Firebase key) dan nama (misal: "R2") dari database
            value['key'] = e.key as String;
            value['nama'] = value['nama'] ?? '';
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
    // Contoh: [tarifNama][4digit][caterKode] => R20001D
    final ref = FirebaseDatabase.instance.ref('pelanggan');
    final snapshot = await ref.get();
    int maxUrut = 0;
    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      for (final p in data.values) {
        final pelanggan = Map<dynamic, dynamic>.from(p);
        // Cari ID yang cocok formatnya: [tarifNama][4digit][caterKode]
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

      // Gunakan nama tarif (bukan key Firebase) dan kode cater dari database
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
      appBar: AppBar(title: const Text('Tambah Pelanggan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_selectedCaterKode != null && _selectedTarifKey != null)
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
                  builder: (context, snapshot) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'ID Pelanggan (Otomatis)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(snapshot.data ?? '-'),
                    ),
                  ),
                ),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (v) => v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              TextFormField(
                controller: _telponController,
                decoration: const InputDecoration(labelText: 'No. Telpon'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'No telpon wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTanggalSambung(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Sambung',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _tanggalSambung != null
                              ? "${_tanggalSambung!.day}/${_tanggalSambung!.month}/${_tanggalSambung!.year}"
                              : 'Pilih tanggal',
                          style: TextStyle(
                            color: _tanggalSambung == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _koordinatController,
                decoration: const InputDecoration(labelText: 'Koordinat (lat,long)'),
                validator: (v) => v == null || v.isEmpty ? 'Koordinat wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCaterKode,
                items: _caterList.map((c) {
                  final kode = c['kode'] as String;
                  final nama = c['nama'] ?? '';
                  return DropdownMenuItem<String>(
                    value: kode,
                    child: Text("$kode - $nama"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCaterKode = v),
                decoration: const InputDecoration(labelText: 'Cater'),
                validator: (v) => v == null ? 'Cater wajib dipilih' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTarifKey,
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
                decoration: const InputDecoration(labelText: 'Tarif'),
                validator: (v) => v == null ? 'Tarif wajib dipilih' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _simpanPelanggan,
                        child: const Text('Simpan'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}