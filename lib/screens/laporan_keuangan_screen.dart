import 'package:flutter/material.dart';

class LaporanKeuanganScreen extends StatelessWidget {
  // Data dummy pemasukan
  final List<Map<String, dynamic>> pemasukan = [
    {'tanggal': '2025-07-01', 'keterangan': 'Pembayaran Gardu', 'jumlah': 100000},
    {'tanggal': '2025-07-02', 'keterangan': 'Pembayaran Warung Ibu Ani', 'jumlah': 75000},
    {'tanggal': '2025-07-03', 'keterangan': 'Pembayaran Kos Mbak Dewi', 'jumlah': 125000},
  ];

  // Data dummy pengeluaran
  final List<Map<String, dynamic>> pengeluaran = [
    {'tanggal': '2025-07-01', 'keterangan': 'Beli tinta printer', 'jumlah': 50000},
    {'tanggal': '2025-07-04', 'keterangan': 'Operasional petugas', 'jumlah': 100000},
  ];

  LaporanKeuanganScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double totalPemasukan =
        pemasukan.fold(0, (sum, item) => sum + item['jumlah']);
    double totalPengeluaran =
        pengeluaran.fold(0, (sum, item) => sum + item['jumlah']);
    double saldo = totalPemasukan - totalPengeluaran;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Keuangan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pemasukan'),
              Tab(text: 'Pengeluaran'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ✅ Tab Pemasukan
            buildList('Pemasukan', pemasukan, totalPemasukan),
            // ✅ Tab Pengeluaran
            buildList('Pengeluaran', pengeluaran, totalPengeluaran),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(16),
          child: Text(
            'Saldo saat ini: Rp ${saldo.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList(String title, List<Map<String, dynamic>> data, double total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(item['keterangan']),
                  subtitle: Text('Tanggal: ${item['tanggal']}'),
                  trailing: Text('Rp ${item['jumlah']}'),
                );
              },
            ),
          ),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total $title: Rp ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
