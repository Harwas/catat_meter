import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
      appBar: AppBar(title: const Text('Detail Pelanggan')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : data == null
              ? Center(child: Text('Data pelanggan tidak ditemukan'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text(
                        data!['nama'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      SizedBox(height: 12),
                      Text("ID: ${data!['id'] ?? '-'}"),
                      Text("Cater: ${data!['cater'] ?? '-'}"),
                      Text("Tarif: ${data!['tarif_cater']?.toString().split('_').first ?? '-'}"),
                      Text("Alamat: ${data!['alamat'] ?? '-'}"),
                      Text("No. Telpon: ${data!['no_telpon'] ?? '-'}"),
                      Text("Koordinat: ${data!['koordinat'] ?? '-'}"),
                      Text("Tanggal Sambung: ${data!['tanggal_sambung'] ?? '-'}"),
                      SizedBox(height: 18),
                      Text("Stand Awal: ${data!['stand_awal'] ?? '-'}"),
                      Text("Stand Baru: ${data!['stand_baru'] ?? '-'}"),
                      Text("Kubikasi: ${data!['kubikasi'] ?? '-'}"),
                      Text("Tagihan: ${data!['tagihan'] ?? '-'}"),
                      Text("Dibayar: ${data!['dibayar'] ?? '-'}"),
                      Text("Terhutang: ${data!['terhutang'] ?? '-'}"),
                    ],
                  ),
                ),
    );
  }
}