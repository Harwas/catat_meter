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
  List<Map<dynamic, dynamic>> _filteredList = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            final pelanggan = Map<String, dynamic>.from(data);
            pelanggan['id'] = pelanggan['id'] ?? key; // pastikan id tetap ada
            list.add(pelanggan);
          }
        });
      }
    }
    setState(() {
      _pelangganList = list;
      _filteredList = list;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredList = query.isEmpty
          ? _pelangganList
          : _pelangganList.where((pelanggan) {
              final nama = (pelanggan['nama'] ?? '').toString().toLowerCase();
              final alamat = (pelanggan['alamat'] ?? '').toString().toLowerCase();
              final id = (pelanggan['id'] ?? '').toString().toLowerCase();
              return nama.contains(query) || alamat.contains(query) || id.contains(query);
            }).toList();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTambahPelanggan,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Pelanggan',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: const Color(0xFF2196F3),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.blue.shade200, width: 2),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari Pelanggan (nama, alamat, id)',
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 16),
                        prefixIcon: Icon(Icons.search, color: Colors.blue, size: 24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada data pelanggan.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final pelanggan = _filteredList[index];
                            return GestureDetector(
                              onTap: () => _navigateToDetailPelanggan(pelanggan['id']),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.blue.shade200, width: 2),
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
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _getAvatarColor(index),
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(25),
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.blue[800],
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pelanggan['nama'] ?? 'NAMA PELANGGAN',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2196F3),
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'PADUKUHAN : ${pelanggan['alamat'] ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2196F3),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'TANGGAL : ${pelanggan['tanggal_sambung'] != null && pelanggan['tanggal_sambung'] != "" ? pelanggan['tanggal_sambung'].toString().split('T').first : ""}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2196F3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text(
                                          pelanggan['id'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.yellow[200]!,
      Colors.orange[200]!,
      Colors.blue[200]!,
      Colors.pink[200]!,
    ];
    return colors[index % colors.length];
  }
}