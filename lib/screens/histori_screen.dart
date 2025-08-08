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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'HISTORY PENCATATAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '& PEMBAYARAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEB3B),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/PROFIL.PNG',
                width: 35,
                height: 35,
                fit: BoxFit.contain,
                // Menangani error jika gambar tidak ditemukan
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : historyList.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada histori pencatatan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: historyList.length,
                    itemBuilder: (context, i) {
                      final item = historyList[i];
                      final kubikasi = (item['stand_baru'] ?? 0) - (item['stand_awal'] ?? 0);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header dengan tanggal
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tanggal: ${_formatTanggal(item['tanggal'])}',
                                  style: const TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Data pembayaran
                              _buildDataRow('Stand Awal:', '', '${item['stand_awal'] ?? 0}'),
                              _buildDataRow('Stand Baru:', '', '${item['stand_baru'] ?? 0}'),
                              _buildDataRow('Kubikasi:', '', '$kubikasi m³'),
                              _buildDataRow('Total Tagihan', '', 'Rp ${item['total_tagihan'] ?? 0}'),
                              _buildDataRow('Nominal Dibayar', '', 'Rp ${item['pembayaran'] ?? 0}'),
                              _buildDataRow('Hutang:', '', 'Rp ${item['terhutang'] ?? 0}', 
                                isHutang: true, 
                                hutangValue: item['terhutang'] ?? 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDataRow(String label, String centerValue, String rightValue, 
      {bool isHutang = false, dynamic hutangValue}) {
    Color textColor = Colors.black;
    if (isHutang && hutangValue != null) {
      textColor = hutangValue > 0 ? Colors.red : Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Label (kiri)
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          // Nilai tengah (jika ada)
          if (centerValue.isNotEmpty)
            Expanded(
              flex: 1,
              child: Text(
                centerValue,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          // Nilai kanan
          Expanded(
            flex: 2,
            child: Text(
              rightValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: isHutang ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(dynamic isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString?.toString() ?? '-';
    }
  }
}