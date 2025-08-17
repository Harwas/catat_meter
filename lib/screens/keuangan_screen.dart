import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';

// Data model
class KeuanganItem {
  final String id;
  // Only for pendapatan
  final String pelangganId;
  final String pelangganNama;
  final int pembayaran;
  final int standAwal;
  final int standAkhir;
  final int terhutang;
  final int totalTagihan;
  // Common
  final String tanggal;
  final String kategori; // "pendapatan", "pemasukkan", "pengeluaran"
  // Only for pemasukkan/pengeluaran
  final String judul;
  final int nominal;

  KeuanganItem({
    required this.id,
    this.pelangganId = '',
    this.pelangganNama = '',
    this.pembayaran = 0,
    this.standAwal = 0,
    this.standAkhir = 0,
    this.terhutang = 0,
    this.totalTagihan = 0,
    this.tanggal = '',
    this.kategori = '',
    this.judul = '',
    this.nominal = 0,
  });
}

class KeuanganScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const KeuanganScreen({required this.currentUser, Key? key}) : super(key: key);

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
      final now = DateTime.now();
      final bulanIni = now.month;
      final tahunIni = now.year;

      // Ambil Pendapatan dari pembayaran
      final pembayaranSnap = await FirebaseDatabase.instance.ref('pembayaran').get();
      pendapatan = [];
      if (pembayaranSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pembayaranSnap.value as Map);
        pendapatan = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          final tanggalStr = item['tanggal'] ?? '';
          DateTime? tgl;
          try {
            tgl = DateTime.parse(tanggalStr);
          } catch (_) {}
          return KeuanganItem(
            id: e.key,
            pelangganId: item['pelanggan_id']?.toString() ?? '',
            pelangganNama: item['pelanggan_nama']?.toString() ?? '',
            pembayaran: (item['pembayaran'] ?? 0) is int
                ? (item['pembayaran'] ?? 0)
                : int.tryParse(item['pembayaran'].toString()) ?? 0,
            standAwal: (item['stand_awal'] ?? 0) is int
                ? (item['stand_awal'] ?? 0)
                : int.tryParse(item['stand_awal'].toString()) ?? 0,
            standAkhir: (item['stand_baru'] ?? 0) is int
                ? (item['stand_baru'] ?? 0)
                : int.tryParse(item['stand_baru'].toString()) ?? 0,
            terhutang: (item['terhutang'] ?? 0) is int
                ? (item['terhutang'] ?? 0)
                : int.tryParse(item['terhutang'].toString()) ?? 0,
            totalTagihan: (item['total_tagihan'] ?? 0) is int
                ? (item['total_tagihan'] ?? 0)
                : int.tryParse(item['total_tagihan'].toString()) ?? 0,
            tanggal: tanggalStr,
            kategori: 'pendapatan',
          );
        }).where((item) {
          DateTime? tgl;
          try {
            tgl = DateTime.parse(item.tanggal);
          } catch (_) {}
          return item.pembayaran > 0 && tgl != null && tgl.month == bulanIni && tgl.year == tahunIni;
        }).toList();
      }

      // Ambil Pemasukkan
      final pemasukkanSnap = await FirebaseDatabase.instance.ref('pemasukkan').get();
      pemasukkan = [];
      if (pemasukkanSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pemasukkanSnap.value as Map);
        pemasukkan = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          final tanggalStr = item['tanggal'] ?? '';
          DateTime? tgl;
          try {
            tgl = DateTime.parse(tanggalStr);
          } catch (_) {}
          return KeuanganItem(
            id: e.key,
            kategori: 'pemasukkan',
            judul: item['judul'] ?? '',
            nominal: item['nominal'] ?? 0,
            tanggal: tanggalStr,
          );
        }).where((item) {
          DateTime? tgl;
          try {
            tgl = DateTime.parse(item.tanggal);
          } catch (_) {}
          return tgl != null && tgl.month == bulanIni && tgl.year == tahunIni;
        }).toList();
      }

      // Ambil Pengeluaran
      final pengeluaranSnap = await FirebaseDatabase.instance.ref('pengeluaran').get();
      pengeluaran = [];
      if (pengeluaranSnap.exists) {
        final data = Map<dynamic, dynamic>.from(pengeluaranSnap.value as Map);
        pengeluaran = data.entries.map((e) {
          final item = Map<dynamic, dynamic>.from(e.value);
          final tanggalStr = item['tanggal'] ?? '';
          DateTime? tgl;
          try {
            tgl = DateTime.parse(tanggalStr);
          } catch (_) {}
          return KeuanganItem(
            id: e.key,
            kategori: 'pengeluaran',
            judul: item['judul'] ?? '',
            nominal: item['nominal'] ?? 0,
            tanggal: tanggalStr,
          );
        }).where((item) {
          DateTime? tgl;
          try {
            tgl = DateTime.parse(item.tanggal);
          } catch (_) {}
          return tgl != null && tgl.month == bulanIni && tgl.year == tahunIni;
        }).toList();
      }
    } catch (e) {
      pendapatan = [];
      pemasukkan = [];
      pengeluaran = [];
    }

    setState(() => _loading = false);
  }

  Future<void> _exportExcel() async {
    final excel.Excel excelFile = excel.Excel.createExcel();

    // Pendapatan Sheet (histori pembayaran)
    excel.Sheet pendSheet = excelFile['Pendapatan'];
    pendSheet.appendRow([
      'No',
      'ID Pelanggan',
      'Nama Pelanggan',
      'Pembayaran',
      'Stand Awal',
      'Stand Akhir',
      'Terhutang',
      'Total Tagihan',
      'Tanggal'
    ]);
    for (int i = 0; i < pendapatan.length; i++) {
      var item = pendapatan[i];
      pendSheet.appendRow([
        i + 1,
        item.pelangganId,
        item.pelangganNama,
        item.pembayaran,
        item.standAwal,
        item.standAkhir,
        item.terhutang,
        item.totalTagihan,
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
    // Contoh: role-based, hanya admin & bendahara dapat tambah pemasukkan/pengeluaran
    final bool canTransact = widget.currentUser['role'] == 'admin' || widget.currentUser['role'] == 'bendahara';

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text(
          'KEUANGAN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSection('Pendapatan', pendapatan, isPendapatan: true),
                    const SizedBox(height: 16),
                    _buildSection(
                      'Pemasukkan',
                      pemasukkan,
                      isPendapatan: false,
                      action: canTransact ? () => _tambahTransaksi('pemasukkan') : null,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      'Pengeluaran',
                      pengeluaran,
                      isPendapatan: false,
                      action: canTransact ? () => _tambahTransaksi('pengeluaran') : null,
                    ),
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

  Widget _buildSection(String title, List<KeuanganItem> items, {bool isPendapatan = false, VoidCallback? action}) {
    // PENTING: Hanya tampilkan info ringkas di aplikasi,
    // data detail (stand, pembayaran, terhutang, dll) hanya untuk export!
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
                          if (isPendapatan)
                            Text(
                              "${item.pelangganNama} (${item.pelangganId})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          if (!isPendapatan)
                            Text(
                              item.judul,
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
                          // Tidak menampilkan data detail seperti pembayaran, stand, terhutang, total_tagihan, dsb di UI aplikasi
                        ],
                      ),
                    ),
                    Text(
                      isPendapatan ? 'Rp ${item.pembayaran}' : 'Rp ${item.nominal}',
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

  Future<void> _tambahTransaksi(String kategori) async {
    String judul = '';
    int nominal = 0;
    DateTime? tanggal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        // Misal ingin simpan user yang menambahkan transaksi:
        'petugas_id': widget.currentUser['uid'],
        'petugas_nama': widget.currentUser['username'],
        'petugas_role': widget.currentUser['role'],
      });
      _loadKeuangan();
    }
  }
}