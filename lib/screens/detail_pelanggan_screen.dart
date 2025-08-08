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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DETAIL PELANGGAN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white, size: 24),
            onPressed: () => _navigateToHistory(),
            tooltip: 'Lihat Histori',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(
                  child: Text(
                    'Data pelanggan tidak ditemukan',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainInfoCard(),
                      const SizedBox(height: 24),
                      _buildHistoryButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2196F3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data!['nama'] ?? 'Nama Pelanggan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Basic info
            _buildInfoRow('ID Pelanggan', data!['id'], isBlue: true),
            _buildInfoRow('Kategori', data!['cater_nama'], isBlue: true),
            _buildInfoRow('Jenis Tarif', data!['tarif_nama']?.toString().split('_').first ?? '-', isBlue: true),
            _buildInfoRow('Alamat', data!['alamat'], isBlue: true),
            _buildInfoRow('No Telepon', data!['telpon'], isBlue: true),
            _buildInfoRow('Tanggal Sambung', _formatDate(data!['tanggal_sambung']), isBlue: true),
            
            const SizedBox(height: 20),
            
            // Data Meteran section
            _buildMeterSection(),
            
            const SizedBox(height: 16),
            
            // Pembayaran section
            _buildPaymentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Meteran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              height: 1,
              color: Colors.grey[300],
            ),
            _buildInfoRow('Stand Awal', data!['stand_awal'] ?? '0', isBlue: true),
            _buildInfoRow('Stand Baru', data!['stand_baru'] ?? '0', isBlue: true),
            _buildInfoRow('Kubikasi', data!['kubikasi'] ?? '0', isBlue: true),
            _buildInfoRow('Terakhir Update', _formatDateTime(data!['tanggal_catat']), isBlue: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              height: 1,
              color: Colors.grey[300],
            ),
            _buildInfoRow('Tagihan', data!['tagihan'] ?? '-', isBlue: true),
            _buildInfoRow('Dibayar', data!['dibayar'] ?? '-', isBlue: true),
            _buildInfoRow('Terhutang', data!['terhutang'] ?? '0', isBlue: true),
          ],
        ),
      ),
    );
  }

  // Removed separate card methods as they are now part of main card sections

  Widget _buildInfoRow(String label, dynamic value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isBlue ? const Color(0xFF2196F3) : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                color: isBlue ? const Color(0xFF2196F3) : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.history, color: Colors.white),
        label: const Text(
          'Lihat Histori Pencatatan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _navigateToHistory,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    try {
      DateTime dt = DateTime.parse(dateTime.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}.${dt.millisecond.toString().padLeft(3, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(pelangganId: widget.pelangganId),
      ),
    );
  }
}