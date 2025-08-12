import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_kalkulasi_screen.dart';

class PencatatanScreen extends StatefulWidget {
  @override
  _PencatatanScreenState createState() => _PencatatanScreenState();
}

class _PencatatanScreenState extends State<PencatatanScreen> {
  List<Map<String, dynamic>> pelangganList = [];
  List<Map<String, dynamic>> filteredPelangganList = [];
  bool _loading = true;
  
  // Ganti Firebase Realtime Database dengan Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Enable offline persistence untuk Firestore
    _enableOfflinePersistence();
    _loadPelanggan();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method untuk mengaktifkan offline persistence
  Future<void> _enableOfflinePersistence() async {
  try {
    // Untuk mobile, gunakan Settings bukan enablePersistence()
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print('Offline persistence enabled');
  } catch (e) {
    print('Could not enable offline persistence: $e');
  }
}

  // Menggunakan Firestore dengan real-time listener
  // Method dengan debug logging yang lebih detail
Future<void> _loadPelanggan() async {
  setState(() => _loading = true);
  
  try {
    print('Starting to load pelanggan data...');
    
    // Test koneksi Firestore terlebih dahulu
    final testDoc = await _firestore.collection('pelanggan').limit(1).get();
    print('Test connection successful. Documents found: ${testDoc.docs.length}');
    
    // Menggunakan snapshots() untuk real-time updates
    _firestore
        .collection('pelanggan')
        .snapshots(includeMetadataChanges: true)
        .listen(
      (QuerySnapshot snapshot) {
        print('Received snapshot with ${snapshot.docs.length} documents');
        final List<Map<String, dynamic>> list = [];
        
        for (var doc in snapshot.docs) {
          print('Processing document: ${doc.id}');
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('Document data: $data');
          data['docId'] = doc.id;
          list.add(data);
        }
        
        print('Total processed documents: ${list.length}');
        
        setState(() {
          pelangganList = list;
          filteredPelangganList = list;
          _loading = false;
        });
        
        // Status koneksi
        if (snapshot.metadata.isFromCache) {
          print('Data dari cache (offline)');
          _showConnectionStatus('Offline - Data dari cache', Colors.orange);
        } else {
          print('Data dari server (online)');
          _showConnectionStatus('Online - Data terbaru', Colors.green);
        }
      },
      onError: (error) {
        print('Error loading pelanggan: $error');
        setState(() => _loading = false);
        _showConnectionStatus('Error: $error', Colors.red);
      },
    );
  } catch (e) {
    print('Error setting up listener: $e');
    setState(() => _loading = false);
    _showConnectionStatus('Setup error: $e', Colors.red);
  }
}

  // Method untuk menampilkan status koneksi
  void _showConnectionStatus(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Method untuk manual refresh (tetap berguna untuk force refresh)
  Future<void> _manualRefresh() async {
    try {
      // Menggunakan get() untuk sekali ambil data (akan tetap menggunakan cache jika offline)
      final QuerySnapshot snapshot = await _firestore
          .collection('pelanggan')
          .get(GetOptions(source: Source.serverAndCache)); // Coba server dulu, fallback ke cache
      
      final List<Map<String, dynamic>> list = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        list.add(data);
      }
      
      setState(() {
        pelangganList = list;
        filteredPelangganList = list;
      });
      
      if (snapshot.metadata.isFromCache) {
        _showConnectionStatus('Refreshed from cache (offline)', Colors.orange);
      } else {
        _showConnectionStatus('Refreshed from server', Colors.green);
      }
    } catch (e) {
      print('Error manual refresh: $e');
      _showConnectionStatus('Refresh failed', Colors.red);
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
                      // Refresh Button - sekarang menggunakan manual refresh
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF2196F3)),
                          onPressed: _manualRefresh,
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
                          onRefresh: _manualRefresh, // Menggunakan manual refresh
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
                                              FormKalkulasiScreen(pelanggan: pelanggan),
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