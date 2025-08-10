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
    
    // ============ PERBAIKAN 1: Style untuk Header ============
    final headerStyle = excel.CellStyle(
      backgroundColorHex: '#2196F3',
      fontColorHex: '#FFFFFF',
      bold: true,
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );
    
    final dataStyle = excel.CellStyle(
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );
    
    final numberStyle = excel.CellStyle(
      horizontalAlign: excel.HorizontalAlign.Right,
      verticalAlign: excel.VerticalAlign.Center,
    );

    // ============ PERBAIKAN 2: Pendapatan Sheet dengan Styling ============
    excel.Sheet pendSheet = excelFile['Pendapatan'];
    excelFile.delete('Sheet1'); // Hapus sheet default
    
    // Header dengan style
    var headerRow = ['No', 'Pelanggan ID', 'Nominal', 'Tanggal'];
    for (int i = 0; i < headerRow.length; i++) {
      var cell = pendSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headerRow[i];
      cell.cellStyle = headerStyle;
    }
    
    // Data dengan nomor urut dan format currency
    for (int i = 0; i < pendapatan.length; i++) {
      var item = pendapatan[i];
      int row = i + 1;
      
      // No urut
      var noCell = pendSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      noCell.value = i + 1;
      noCell.cellStyle = numberStyle;
      
      // Pelanggan ID
      var pelangganCell = pendSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      pelangganCell.value = item.pelangganId ?? '-';
      pelangganCell.cellStyle = dataStyle;
      
      // Nominal dengan format Rupiah
      var nominalCell = pendSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      nominalCell.value = 'Rp ${_formatNumber(item.nominal)}';
      nominalCell.cellStyle = numberStyle;
      
      // Tanggal
      var tanggalCell = pendSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      tanggalCell.value = _formatTanggal(item.tanggal);
      tanggalCell.cellStyle = dataStyle;
    }
    
    // ============ PERBAIKAN 3: Tambah baris kosong untuk spacing ============

    // ============ PERBAIKAN 4: Pemasukkan Sheet dengan Styling ============
    excel.Sheet masukSheet = excelFile['Pemasukkan'];
    
    headerRow = ['No', 'Judul', 'Nominal', 'Tanggal'];
    for (int i = 0; i < headerRow.length; i++) {
      var cell = masukSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headerRow[i];
      cell.cellStyle = headerStyle;
    }
    
    for (int i = 0; i < pemasukkan.length; i++) {
      var item = pemasukkan[i];
      int row = i + 1;
      
      var noCell = masukSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      noCell.value = i + 1;
      noCell.cellStyle = numberStyle;
      
      var judulCell = masukSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      judulCell.value = item.judul;
      judulCell.cellStyle = dataStyle;
      
      var nominalCell = masukSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      nominalCell.value = 'Rp ${_formatNumber(item.nominal)}';
      nominalCell.cellStyle = numberStyle;
      
      var tanggalCell = masukSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      tanggalCell.value = _formatTanggal(item.tanggal);
      tanggalCell.cellStyle = dataStyle;
    }
    

    // ============ PERBAIKAN 5: Pengeluaran Sheet dengan Styling ============
    excel.Sheet keluarSheet = excelFile['Pengeluaran'];
    
    headerRow = ['No', 'Judul', 'Nominal', 'Tanggal'];
    for (int i = 0; i < headerRow.length; i++) {
      var cell = keluarSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headerRow[i];
      cell.cellStyle = headerStyle;
    }
    
    for (int i = 0; i < pengeluaran.length; i++) {
      var item = pengeluaran[i];
      int row = i + 1;
      
      var noCell = keluarSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      noCell.value = i + 1;
      noCell.cellStyle = numberStyle;
      
      var judulCell = keluarSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      judulCell.value = item.judul;
      judulCell.cellStyle = dataStyle;
      
      var nominalCell = keluarSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      nominalCell.value = 'Rp ${_formatNumber(item.nominal)}';
      nominalCell.cellStyle = numberStyle;
      
      var tanggalCell = keluarSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      tanggalCell.value = _formatTanggal(item.tanggal);
      tanggalCell.cellStyle = dataStyle;
    }
    

    // ============ PERBAIKAN 6: Sheet Ringkasan ============
    excel.Sheet ringkasanSheet = excelFile['Ringkasan'];
    
    // Header ringkasan
    var ringkasanCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    ringkasanCell.value = 'RINGKASAN KEUANGAN';
    ringkasanCell.cellStyle = excel.CellStyle(
      backgroundColorHex: '#FFD700',
      fontColorHex: '#000000',
      bold: true,
      fontSize: 16,
      horizontalAlign: excel.HorizontalAlign.Center,
    );
    
    // Total Pendapatan
    int totalPendapatan = pendapatan.fold(0, (sum, item) => sum + item.nominal);
    var pendapatanLabelCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    pendapatanLabelCell.value = 'Total Pendapatan:';
    pendapatanLabelCell.cellStyle = excel.CellStyle(bold: true);
    
    var pendapatanValueCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2));
    pendapatanValueCell.value = 'Rp ${_formatNumber(totalPendapatan)}';
    pendapatanValueCell.cellStyle = excel.CellStyle(
      backgroundColorHex: '#E8F5E8',
      horizontalAlign: excel.HorizontalAlign.Right,
    );
    
    // Total Pemasukkan
    int totalPemasukkan = pemasukkan.fold(0, (sum, item) => sum + item.nominal);
    var pemasukkanLabelCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3));
    pemasukkanLabelCell.value = 'Total Pemasukkan:';
    pemasukkanLabelCell.cellStyle = excel.CellStyle(bold: true);
    
    var pemasukkanValueCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3));
    pemasukkanValueCell.value = 'Rp ${_formatNumber(totalPemasukkan)}';
    pemasukkanValueCell.cellStyle = excel.CellStyle(
      backgroundColorHex: '#E8F5E8',
      horizontalAlign: excel.HorizontalAlign.Right,
    );
    
    // Total Pengeluaran
    int totalPengeluaran = pengeluaran.fold(0, (sum, item) => sum + item.nominal);
    var pengeluaranLabelCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4));
    pengeluaranLabelCell.value = 'Total Pengeluaran:';
    pengeluaranLabelCell.cellStyle = excel.CellStyle(bold: true);
    
    var pengeluaranValueCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4));
    pengeluaranValueCell.value = 'Rp ${_formatNumber(totalPengeluaran)}';
    pengeluaranValueCell.cellStyle = excel.CellStyle(
      backgroundColorHex: '#FFE8E8',
      horizontalAlign: excel.HorizontalAlign.Right,
    );
    
    // Saldo Bersih
    int saldoBersih = totalPendapatan + totalPemasukkan - totalPengeluaran;
    var saldoLabelCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6));
    saldoLabelCell.value = 'Saldo Bersih:';
    saldoLabelCell.cellStyle = excel.CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: '#FFD700',
    );
    
    var saldoValueCell = ringkasanSheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6));
    saldoValueCell.value = 'Rp ${_formatNumber(saldoBersih)}';
    saldoValueCell.cellStyle = excel.CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: saldoBersih >= 0 ? '#E8F5E8' : '#FFE8E8',
      horizontalAlign: excel.HorizontalAlign.Right,
    );
    

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

  // ============ PERBAIKAN 7: Fungsi Helper untuk Format Number ============
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
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