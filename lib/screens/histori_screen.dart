import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatefulWidget {
  final String pelangganId;
  const HistoryScreen({required this.pelangganId, Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<dynamic, dynamic>> historyList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseDatabase.instance.ref('pembayaran').get();

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        // Filter hanya histori dengan pelangganId sesuai
        historyList = data.values
            .map((e) => Map<dynamic, dynamic>.from(e))
            .where((item) =>
                item['pelanggan_id']?.toString() == widget.pelangganId)
            .toList();
        // Urutkan berdasarkan tanggal terbaru
        historyList.sort((a, b) =>
            (b['tanggal'] ?? '').compareTo(a['tanggal'] ?? ''));
      } else {
        historyList = [];
      }
    } catch (e) {
      historyList = [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histori Pencatatan & Pembayaran')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : historyList.isEmpty
              ? Center(child: Text('Belum ada histori pencatatan'))
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: historyList.length,
                  itemBuilder: (context, i) {
                    final item = historyList[i];
                    final kubikasi = (item['stand_baru'] ?? 0) - (item['stand_awal'] ?? 0);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        title: Text(
                          'Tanggal: ${_formatTanggal(item['tanggal'])}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stand Awal: ${item['stand_awal'] ?? "-"}'),
                            Text('Stand Baru: ${item['stand_baru'] ?? "-"}'),
                            Text('Kubikasi: $kubikasi m³'),
                            Text('Total Tagihan: Rp ${item['total_tagihan'] ?? "0"}'),
                            Text('Nominal Dibayar: Rp ${item['pembayaran'] ?? "0"}'),
                            Text(
                              'Hutang: Rp ${item['terhutang'] ?? "0"}',
                              style: TextStyle(
                                color: (item['terhutang'] ?? 0) > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTanggal(dynamic isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    } catch (e) {
      return isoString?.toString() ?? '-';
    }
  }
}