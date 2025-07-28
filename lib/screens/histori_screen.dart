import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoriScreen extends StatefulWidget {
  final String pelangganId;
  
  const HistoriScreen({required this.pelangganId, Key? key}) : super(key: key);

  @override
  State<HistoriScreen> createState() => _HistoriScreenState();
}

class _HistoriScreenState extends State<HistoriScreen> {
  bool _loading = true;
  List<Map<dynamic, dynamic>> _historiData = [];

  @override
  void initState() {
    super.initState();
    _loadHistori();
  }

  Future<void> _loadHistori() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('histori')
          .orderByChild('tanggal')
          .once();

      if (snapshot.snapshot.exists) {
        final allData = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        
        setState(() {
          _historiData = allData.entries
              .where((entry) => entry.key.toString().contains(widget.pelangganId))
              .map((entry) => Map<dynamic, dynamic>.from(entry.value))
              .toList()
            ..sort((a, b) => b['tanggal'].compareTo(a['tanggal']));
          _loading = false;
        });
      } else {
        setState(() {
          _historiData = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _historiData = [];
        _loading = false;
      });
      print('Error loading history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histori Pencatatan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _historiData.isEmpty
              ? Center(child: Text('Belum ada histori pencatatan'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _historiData.length,
                  itemBuilder: (context, index) {
                    final record = _historiData[index];
                    final date = DateTime.parse(record['tanggal']);
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Divider(),
                            _buildHistoriRow('Stand Awal', '${record['stand_awal']} m³'),
                            _buildHistoriRow('Stand Baru', '${record['stand_baru']} m³'),
                            _buildHistoriRow('Pemakaian', '${record['kubikasi']} m³'),
                            _buildHistoriRow('Tarif', 'Rp ${record['harga_per_m3']}/m³'),
                            Divider(),
                            _buildHistoriRow(
                              'Total Tagihan',
                              'Rp ${record['tagihan']}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildHistoriRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: isBold ? TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}