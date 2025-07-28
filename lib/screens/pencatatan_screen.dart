import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'form_kalkulasi_screen.dart';

class PencatatanScreen extends StatefulWidget {
  const PencatatanScreen({Key? key}) : super(key: key);

  @override
  _PencatatanScreenState createState() => _PencatatanScreenState();
}

class _PencatatanScreenState extends State<PencatatanScreen> {
  List<Map<dynamic, dynamic>> _pelangganList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
  }

  Future<void> _loadPelanggan() async {
    final snapshot = await FirebaseDatabase.instance.ref('pelanggan').get();
    if (snapshot.exists) {
      setState(() {
        _pelangganList = [];
        (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
          _pelangganList.add(Map<dynamic, dynamic>.from(value));
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pelanggan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _pelangganList.length,
              itemBuilder: (context, index) {
                final pelanggan = _pelangganList[index];
                return ListTile(
                  title: Text(pelanggan['nama'] ?? ''),
                  subtitle: Text('${pelanggan['id']} - Tarif: ${pelanggan['tarif']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormKalkulasiScreen(pelanggan: pelanggan),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}