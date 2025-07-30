import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form_kalkulasi_screen.dart';

class PencatatanScreen extends StatefulWidget {
  @override
  _PencatatanScreenState createState() => _PencatatanScreenState();
}

class _PencatatanScreenState extends State<PencatatanScreen> {
  List<Map<dynamic, dynamic>> pelangganList = [];
  bool _loading = true;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
  }

  Future<void> _loadPelanggan() async {
    try {
      final snapshot = await _databaseRef.child('pelanggan').get();
      if (snapshot.exists) {
        setState(() {
          pelangganList = [];
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          data.forEach((key, value) {
            pelangganList.add(Map<dynamic, dynamic>.from(value));
          });
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading pelanggan: $e');
      setState(() => _loading = false);
    }
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
          : pelangganList.isEmpty
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
                    itemCount: pelangganList.length,
                    itemBuilder: (context, index) {
                      final pelanggan = pelangganList[index];
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
                              Text('Tarif: ${pelanggan['tarif']?.toString().split('_').first ?? '-'}'),
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
    );
  }
}