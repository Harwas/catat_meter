import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';

// Data model
class KeuanganItem {
  final String id;
  final int nominal;
  final String judul;
  final String tanggal;
  final String kategori; // "pendapatan", "pemasukkan", "pengeluaran"
  final String? pelangganId; // hanya pendapatan

  KeuanganItem({
    required this.id,
    required this.nominal,
    required this.judul,
    required this.tanggal,
    required this.kategori,
    this.pelangganId,
  });
}

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({Key? key}) : super(key: key);

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  List<KeuanganItem> pendapatan = [];
  List<KeuanganItem> pemasukkan = [];
  List<KeuanganItem> pengeluaran = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeuangan();
  }

  Future<void> _loadKeuangan() async {
    setState(() => _loading = true);

    try {
      // Ambil Pendapatan dari pembayaran
      final pembayaranSnap = await FirebaseDatabase.instance.ref('pembayaran').get();
      pendapatan = [];
      if (pembayaranSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pembayaranSnap.value as Map);
        pendapatan = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          return KeuanganItem(
            id: e.key,
            nominal: item['pembayaran'] ?? 0,
            judul: item['pelanggan_id']?.toString() ?? '',
            tanggal: item['tanggal'] ?? '',
            kategori: 'pendapatan',
            pelangganId: item['pelanggan_id']?.toString(),
          );
        }).where((item) => item.nominal > 0).toList();
      }

      // Ambil Pemasukkan
      final pemasukkanSnap = await FirebaseDatabase.instance.ref('pemasukkan').get();
      pemasukkan = [];
      if (pemasukkanSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pemasukkanSnap.value as Map);
        pemasukkan = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          return KeuanganItem(
            id: e.key,
            nominal: item['nominal'] ?? 0,
            judul: item['judul'] ?? '',
            tanggal: item['tanggal'] ?? '',
            kategori: 'pemasukkan',
          );
        }).toList();
      }

      // Ambil Pengeluaran
      final pengeluaranSnap = await FirebaseDatabase.instance.ref('pengeluaran').get();
      pengeluaran = [];
      if (pengeluaranSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pengeluaranSnap.value as Map);
        pengeluaran = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          return KeuanganItem(
            id: e.key,
            nominal: item['nominal'] ?? 0,
            judul: item['judul'] ?? '',
            tanggal: item['tanggal'] ?? '',
            kategori: 'pengeluaran',
          );
        }).toList();
      }
    } catch (e) {
      pendapatan = [];
      pemasukkan = [];
      pengeluaran = [];
    }

    setState(() => _loading = false);
  }

  Future<void> _tambahTransaksi(String kategori) async {
  String judul = '';
  int nominal = 0;
  DateTime? tanggal;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // biar tinggi mengikuti konten
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      final _judulController = TextEditingController();
      final _nominalController = TextEditingController();
      DateTime selectedDate = DateTime.now();

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tambah $kategori',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Tanggal: ${_formatTanggal(selectedDate.toIso8601String())}",
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text(
                      'Pilih Tanggal',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Color(0xFF2196F3))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      judul = _judulController.text;
                      nominal = int.tryParse(_nominalController.text) ?? 0;
                      tanggal = selectedDate;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );

  // Simpan transaksi jika valid
  if (judul.isNotEmpty && nominal > 0 && tanggal != null) {
    final idTransaksi = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseDatabase.instance.ref('$kategori/$idTransaksi').set({
      'judul': judul,
      'nominal': nominal,
      'tanggal': tanggal!.toIso8601String(),
    });
    _loadKeuangan();
  }
}


  Future<void> _exportExcel() async {
    final excel.Excel excelFile = excel.Excel.createExcel();
    
    // Pendapatan Sheet
    excel.Sheet pendSheet = excelFile['Pendapatan'];
    pendSheet.appendRow(['ID', 'Nominal', 'Pelanggan ID', 'Tanggal']);
    for (var item in pendapatan) {
      pendSheet.appendRow([
        item.id,
        item.nominal,
        item.pelangganId ?? '',
        _formatTanggal(item.tanggal),
      ]);
    }

    // Pemasukkan Sheet
    excel.Sheet masukSheet = excelFile['Pemasukkan'];
    masukSheet.appendRow(['ID', 'Nominal', 'Judul', 'Tanggal']);
    for (var item in pemasukkan) {
      masukSheet.appendRow([
        item.id,
        item.nominal,
        item.judul,
        _formatTanggal(item.tanggal),
      ]);
    }

    // Pengeluaran Sheet
    excel.Sheet keluarSheet = excelFile['Pengeluaran'];
    keluarSheet.appendRow(['ID', 'Nominal', 'Judul', 'Tanggal']);
    for (var item in pengeluaran) {
      keluarSheet.appendRow([
        item.id,
        item.nominal,
        item.judul,
        _formatTanggal(item.tanggal),
      ]);
    }

    // Simpan ke folder Documents umum di Android
    String filePath;
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      filePath = '${directory.path}/keuangan_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excelFile.save()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File Excel berhasil disimpan di: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSection('Pendapatan', pendapatan),
                    const SizedBox(height: 16),
                    _buildSection('Pemasukkan', pemasukkan, action: () => _tambahTransaksi('pemasukkan')),
                    const SizedBox(height: 16),
                    _buildSection('Pengeluaran', pengeluaran, action: () => _tambahTransaksi('pengeluaran')),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _exportExcel,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.file_download, color: Colors.white),
        tooltip: 'Export ke Excel',
      ),
    );
  }

  Widget _buildSection(String title, List<KeuanganItem> items, {VoidCallback? action}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow[700]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const Spacer(),
                if (action != null)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: action,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Belum ada data',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.judul.isNotEmpty ? item.judul : (item.pelangganId ?? '-'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          Text(
                            _formatTanggal(item.tanggal),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${item.nominal}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(dynamic isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return isoString?.toString() ?? '-';
    }
  }
}