import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'detail_pelanggan_screen.dart';
import 'tambah_pelanggan_screen.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({Key? key}) : super(key: key);

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  List<Map<dynamic, dynamic>> _pelangganList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
  }

  Future<void> _fetchPelanggan() async {
    setState(() {
      _loading = true;
    });
    final snapshot = await FirebaseDatabase.instance.ref('pelanggan').get();
    List<Map<dynamic, dynamic>> list = [];
    if (snapshot.exists) {
      final value = snapshot.value;
      if (value is Map) {
        value.forEach((key, data) {
          if (data is Map) {
            list.add(Map<String, dynamic>.from(data));
          }
        });
      }
    }
    setState(() {
      _pelangganList = list;
      _loading = false;
    });
  }

  void _navigateToTambahPelanggan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahPelangganScreen(),
      ),
    );
    if (result != null) {
      _fetchPelanggan();
    }
  }

  void _navigateToDetailPelanggan(String pelangganId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPelangganScreen(pelangganId: pelangganId),
      ),
    );
    // Bisa refresh data jika perlu setelah kembali dari detail
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchPelanggan,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTambahPelanggan,
        child: Icon(Icons.add),
        tooltip: 'Tambah Pelanggan',
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _pelangganList.isEmpty
              ? Center(child: Text('Belum ada data pelanggan.'))
              : ListView.builder(
                  itemCount: _pelangganList.length,
                  itemBuilder: (context, index) {
                    final pelanggan = _pelangganList[index];
                    return GestureDetector(
                      onTap: () => _navigateToDetailPelanggan(pelanggan['id']),
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.blue.shade300, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.yellow[200],
                                child: Icon(Icons.person, color: Colors.blue[800]),
                                radius: 28,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pelanggan['nama'] ?? '-',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'PADUKUHAN : ${pelanggan['alamat'] ?? '-'}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'TANGGAL : ${pelanggan['tanggal_sambung'] != null && pelanggan['tanggal_sambung'] != "" ? pelanggan['tanggal_sambung'].toString().split('T').first : ""}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                pelanggan['id'] ?? '',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}