import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart';
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

    await showDialog(
      context: context,
      builder: (context) {
        final _judulController = TextEditingController();
        final _nominalController = TextEditingController();
        DateTime selectedDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Tambah $kategori'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _judulController,
                  decoration: InputDecoration(labelText: 'Judul'),
                ),
                TextField(
                  controller: _nominalController,
                  decoration: InputDecoration(labelText: 'Nominal'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text("Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                    Spacer(),
                    TextButton(
                      child: Text('Pilih Tanggal'),
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
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Simpan'),
                onPressed: () {
                  judul = _judulController.text;
                  nominal = int.tryParse(_nominalController.text) ?? 0;
                  tanggal = selectedDate;
                  Navigator.pop(context);
                },
              ),
            ],
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
    var excel = Excel.createExcel();
    // Pendapatan Sheet
    Sheet pendSheet = excel['Pendapatan'];
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
    Sheet masukSheet = excel['Pemasukkan'];
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
    Sheet keluarSheet = excel['Pengeluaran'];
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
      await file.writeAsBytes(excel.save()!);

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
      appBar: AppBar(
        actions: [
          Container(
            width: 60,
            height: 40,
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.file_download, color: Colors.white, size: 20),
              tooltip: 'Export ke Excel',
              onPressed: _loading ? null : _exportExcel,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Data Meteran Section
                    _buildSection('Pendapatan', pendapatan, Colors.blue[50]!),
                    const SizedBox(height: 16),
                    
                    // Pemasukkan Section
                    _buildSection('Pemasukkan', pemasukkan, const Color(0xFFE1F5FE),
                      action: () => _tambahTransaksi('pemasukkan')),
                    const SizedBox(height: 16),
                    
                    // Pengeluaran Section
                    _buildSection('Pengeluaran', pengeluaran, const Color(0xFFE1F5FE),
                      action: () => _tambahTransaksi('pengeluaran')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<KeuanganItem> items, Color backgroundColor, {VoidCallback? action}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan title dan tombol tambah
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: title == 'Pendapatan' 
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF2196F3),
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
            
            // List items
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: title == 'Pendapatan' 
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF2196F3),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: title == 'Data Meteran' 
                          ? const Color(0xFF2196F3)
                          : Colors.black87,
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