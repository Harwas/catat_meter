import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahPelangganScreen extends StatefulWidget {
  const TambahPelangganScreen({Key? key}) : super(key: key);

  @override
  State<TambahPelangganScreen> createState() => _TambahPelangganScreenState();
}

class _TambahPelangganScreenState extends State<TambahPelangganScreen> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final noTelponController = TextEditingController();
  final koordinatController = TextEditingController();
  DateTime? tanggalSambung;

  // Dropdown options
  final List<String> tarifList = ['R1', 'S1', 'P1'];
  final List<String> caterList = ['Roy', 'Sari', 'Putra'];
  String? selectedTarif;
  String? selectedCater;

  bool _loading = false;

  Future<int> getNextUrut(String tarif, String cater) async {
    String counterKey = "${tarif}_${cater}";
    DatabaseReference counterRef = FirebaseDatabase.instance.ref('counter/$counterKey');

    final snapshot = await counterRef.get();
    int nomor = 1;
    if (snapshot.exists) {
      nomor = (snapshot.value as int) + 1;
    }
    await counterRef.set(nomor); // update counter
    return nomor;
  }

  String generateId(String tarif, String cater, int nomorUrut) {
    // Akhiran ID berdasarkan cater
    String kodeAkhir = cater.toLowerCase() == "roy"
        ? "A"
        : cater.toLowerCase() == "sari"
            ? "B"
            : cater.toLowerCase() == "putra"
                ? "C"
                : "X";
    // Format: R1001A (tanpa angka 1 ganda)
    return "${tarif.toUpperCase()}${nomorUrut.toString().padLeft(3, '0')}$kodeAkhir";
  }

  void _simpanPelanggan() async {
    if (!_formKey.currentState!.validate() || selectedTarif == null || selectedCater == null) return;
    setState(() => _loading = true);

    // Menggunakan counter, bukan scan semua data pelanggan
    final nomorUrut = await getNextUrut(selectedTarif!, selectedCater!);
    final id = generateId(selectedTarif!, selectedCater!, nomorUrut);

    final pelanggan = {
      'id': id,
      'tarif_cater': "${selectedTarif!}_${selectedCater!}",
      'nama': namaController.text,
      'qr_code_url': "",
      'cater': selectedCater!,
      'alamat': alamatController.text,
      'no_telpon': int.tryParse(noTelponController.text) ?? 0,
      'koordinat': koordinatController.text,
      'tanggal_sambung': tanggalSambung?.toIso8601String() ?? "",
      // Data awal pelanggan baru
      'tanggal_catat': "",
      'stand_awal': 0,
      'stand_baru': 0,
      'kubikasi': 0,
      'tagihan': 0,
      'dibayar': 0,
      'terhutang': 0,
    };

    await FirebaseDatabase.instance.ref('pelanggan/$id').set(pelanggan);

    setState(() => _loading = false);
    Navigator.pop(context, pelanggan);
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
              DropdownButtonFormField<String>(
                value: selectedTarif,
                items: tarifList.map((tarif) {
                  return DropdownMenuItem(
                    value: tarif,
                    child: Text(tarif),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTarif = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Tarif'),
                validator: (v) => v == null ? 'Wajib pilih tarif' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedCater,
                items: caterList.map((cater) {
                  return DropdownMenuItem(
                    value: cater,
                    child: Text(cater),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCater = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Cater'),
                validator: (v) => v == null ? 'Wajib pilih cater' : null,
              ),
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: alamatController,
                decoration: InputDecoration(labelText: 'Alamat'),
              ),
              TextFormField(
                controller: noTelponController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'No. Telpon'),
              ),
              TextFormField(
                controller: koordinatController,
                decoration: InputDecoration(labelText: 'Koordinat'),
              ),
              const SizedBox(height: 8),
              Text('Tanggal Sambung', style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tanggalSambung ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => tanggalSambung = picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    tanggalSambung == null
                        ? 'Pilih tanggal'
                        : "${tanggalSambung!.day}-${tanggalSambung!.month}-${tanggalSambung!.year}",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _simpanPelanggan,
                icon: Icon(Icons.save),
                label: Text(_loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}