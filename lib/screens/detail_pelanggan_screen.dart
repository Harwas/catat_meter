import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'histori_screen.dart';

class DetailPelangganScreen extends StatefulWidget {
  final String pelangganId;
  const DetailPelangganScreen({required this.pelangganId, Key? key}) : super(key: key);

  @override
  State<DetailPelangganScreen> createState() => _DetailPelangganScreenState();
}

class _DetailPelangganScreenState extends State<DetailPelangganScreen> {
  Map<dynamic, dynamic>? data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
  }

  Future<void> _loadPelanggan() async {
    final snapshot = await FirebaseDatabase.instance.ref('pelanggan/${widget.pelangganId}').get();
    if (snapshot.exists) {
      setState(() {
        data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        _loading = false;
      });
    } else {
      setState(() {
        data = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _navigateToHistory(),
            tooltip: 'Lihat Histori',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : data == null
              ? Center(child: Text('Data pelanggan tidak ditemukan'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(),
                      SizedBox(height: 24),
                      _buildMeterSection(),
                      SizedBox(height: 24),
                      _buildPaymentSection(),
                      SizedBox(height: 32),
                      _buildHistoryButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data!['nama'] ?? 'Nama tidak tersedia',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _buildInfoRow('ID Pelanggan', data!['id']),
        _buildInfoRow('Kategori', data!['cater']),
        _buildInfoRow('Jenis Tarif', data!['tarif_cater']?.toString().split('_').first ?? '-'),
        _buildInfoRow('Alamat', data!['alamat']),
        _buildInfoRow('No. Telpon', data!['no_telpon']),
        _buildInfoRow('Tanggal Sambung', data!['tanggal_sambung']),
      ],
    );
  }

  Widget _buildMeterSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Meteran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            _buildInfoRow('Stand Awal', data!['stand_awal']),
            _buildInfoRow('Stand Baru', data!['stand_baru']),
            _buildInfoRow('Kubikasi', data!['kubikasi']),
            _buildInfoRow('Terakhir Update', data!['tanggal_catat']),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            _buildInfoRow('Tagihan', data!['tagihan']),
            _buildInfoRow('Dibayar', data!['dibayar']),
            _buildInfoRow('Terhutang', data!['terhutang']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.history),
      label: Text('Lihat Histori Pencatatan'),
      onPressed: _navigateToHistory,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoriScreen(pelangganId: widget.pelangganId),
      ),
    );
  }
}