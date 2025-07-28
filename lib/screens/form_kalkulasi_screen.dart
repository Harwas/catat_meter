import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class FormKalkulasiScreen extends StatefulWidget {
  final Map<dynamic, dynamic> pelanggan;
  const FormKalkulasiScreen({Key? key, required this.pelanggan}) : super(key: key);

  @override
  _FormKalkulasiScreenState createState() => _FormKalkulasiScreenState();
}

class _FormKalkulasiScreenState extends State<FormKalkulasiScreen> {
  final _standBaruController = TextEditingController();
  bool _loading = false;
  int _kubikasi = 0;
  int _tagihan = 0;
  int _tarifPerKubik = 0;

  @override
  void initState() {
    super.initState();
    _standBaruController.text = widget.pelanggan['stand_baru']?.toString() ?? '';
    _loadTarif();
  }

  Future<void> _loadTarif() async {
    final jenisTarif = widget.pelanggan['tarif'] ?? 'P1';
    final snapshot = await FirebaseDatabase.instance.ref('tarif/$jenisTarif').get();
    setState(() {
      _tarifPerKubik = (snapshot.value as int?) ?? 7000;
    });
  }

  void _hitungTagihan() {
    final standAwal = int.parse(widget.pelanggan['stand_baru']?.toString() ?? '0');
    final standBaru = int.tryParse(_standBaruController.text) ?? standAwal;
    setState(() {
      _kubikasi = standBaru - standAwal;
      _tagihan = _kubikasi * _tarifPerKubik;
    });
  }

  Future<void> _simpanData() async {
    if (_kubikasi <= 0) return;
    
    setState(() => _loading = true);
    final now = DateTime.now();

    try {
      await FirebaseDatabase.instance.ref('pelanggan/${widget.pelanggan['id']}').update({
        'stand_awal': widget.pelanggan['stand_baru'],
        'stand_baru': int.parse(_standBaruController.text),
        'kubikasi': _kubikasi,
        'tagihan': _tagihan,
        'tanggal_catat': now.toIso8601String(),
      });

      await FirebaseDatabase.instance.ref('histori/${widget.pelanggan['id']}/${now.millisecondsSinceEpoch}').set({
        'tanggal': now.toIso8601String(),
        'stand_awal': widget.pelanggan['stand_baru'],
        'stand_baru': int.parse(_standBaruController.text),
        'kubikasi': _kubikasi,
        'tagihan': _tagihan,
        'tarif': _tarifPerKubik,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil disimpan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Stand Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.pelanggan['nama'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('ID: ${widget.pelanggan['id']}'),
            Text('Tarif: ${widget.pelanggan['tarif']} (Rp $_tarifPerKubik/m³)'),
            
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Stand Lama'),
              controller: TextEditingController(
                text: widget.pelanggan['stand_baru']?.toString() ?? '0'),
              enabled: false,
            ),
            
            TextFormField(
              decoration: InputDecoration(labelText: 'Stand Baru'),
              controller: _standBaruController,
              keyboardType: TextInputType.number,
              onChanged: (value) => _hitungTagihan(),
            ),
            
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Pemakaian', '$_kubikasi m³'),
                    _buildDetailRow('Tarif', 'Rp $_tarifPerKubik/m³'),
                    Divider(),
                    _buildDetailRow('Total Tagihan', 'Rp $_tagihan', isBold: true),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simpanData,
              child: _loading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: isBold ? TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}