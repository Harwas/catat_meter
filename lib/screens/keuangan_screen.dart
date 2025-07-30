import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

        return AlertDialog(
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
                        selectedDate = picked;
                        setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keuangan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection('Pendapatan (Otomatis)', pendapatan, Colors.green),
                  Divider(),
                  _buildSection('Pemasukkan', pemasukkan, Colors.blue,
                    action: () => _tambahTransaksi('pemasukkan')),
                  Divider(),
                  _buildSection('Pengeluaran', pengeluaran, Colors.red,
                    action: () => _tambahTransaksi('pengeluaran')),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<KeuanganItem> items, Color color, {VoidCallback? action}) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Spacer(),
                if (action != null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Tambah'),
                    onPressed: action,
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (items.isEmpty)
              Text('Belum ada data', style: TextStyle(color: Colors.grey)),
            ...items.map((item) => ListTile(
              title: Text(item.judul.isNotEmpty ? item.judul : (item.pelangganId ?? '-')),
              subtitle: Text(_formatTanggal(item.tanggal)),
              trailing: Text('Rp ${item.nominal}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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