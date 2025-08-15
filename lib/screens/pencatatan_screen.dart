import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form_kalkulasi_screen.dart';

class PencatatanScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const PencatatanScreen({required this.currentUser, Key? key}) : super(key: key);

  @override
  _PencatatanScreenState createState() => _PencatatanScreenState();
}

class _PencatatanScreenState extends State<PencatatanScreen> {
  List<Map<dynamic, dynamic>> pelangganList = [];
  List<Map<dynamic, dynamic>> filteredPelangganList = [];
  bool _loading = true;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPelanggan() async {
    try {
      final snapshot = await _databaseRef.child('pelanggan').get();
      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final List<Map<dynamic, dynamic>> list = [];
        data.forEach((key, value) {
          final pelanggan = Map<dynamic, dynamic>.from(value);
          pelanggan['id'] = pelanggan['id'] ?? key;
          // Filtering jika cater
          if (widget.currentUser['role'] == 'cater') {
            if (pelanggan['cater_kode'] == widget.currentUser['cater_kode']) {
              list.add(pelanggan);
            }
          } else {
            list.add(pelanggan);
          }
        });
        setState(() {
          pelangganList = list;
          filteredPelangganList = list;
          _loading = false;
        });
      } else {
        setState(() {
          pelangganList = [];
          filteredPelangganList = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading pelanggan: $e');
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPelangganList = pelangganList;
      } else {
        filteredPelangganList = pelangganList.where((pelanggan) {
          final nama = (pelanggan['nama'] ?? '').toString().toLowerCase();
          final id = (pelanggan['id'] ?? '').toString().toLowerCase();
          final tarif = (pelanggan['tarif_nama'] ?? '').toString().toLowerCase();
          return nama.contains(query) || id.contains(query) || tarif.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.currentUser['role'];
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar + Refresh Button
                Container(
                  color: const Color(0xFF2196F3),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      // Expanded Search Field
                      Expanded(
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
                      const SizedBox(width: 8),
                      // Refresh Button
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF2196F3)),
                          onPressed: _loadPelanggan,
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                ),

                // List Pelanggan
                Expanded(
                  child: filteredPelangganList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data pelanggan',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPelanggan,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPelangganList.length,
                            itemBuilder: (context, index) {
                              final pelanggan = filteredPelangganList[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FormKalkulasiScreen(
                                                pelanggan: pelanggan,
                                                currentUser: widget.currentUser,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pelanggan['nama']?.toString() ?? 'NAMA PELANGGAN',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 2,
                                                  width: double.infinity,
                                                  color: Colors.blue[300],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'ID: ${pelanggan['id'] ?? 'R30001D'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tarif: ${pelanggan['tarif_nama']?.toString().split('_').first ?? 'R3'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.blue[600],
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}