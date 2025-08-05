import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form_kalkulasi_screen.dart';

class PencatatanScreen extends StatefulWidget {
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
          list.add(Map<dynamic, dynamic>.from(value));
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pelanggan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPelanggan,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari pelanggan (nama, ID, tarif)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: filteredPelangganList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data pelanggan',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPelanggan,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredPelangganList.length,
                            itemBuilder: (context, index) {
                              final pelanggan = filteredPelangganList[index];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    pelanggan['nama']?.toString() ?? 'Nama tidak tersedia',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${pelanggan['id']}'),
                                      Text('Tarif: ${pelanggan['tarif_nama']?.toString().split('_').first ?? '-'}'),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FormKalkulasiScreen(pelanggan: pelanggan),
                                      ),
                                    );
                                  },
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