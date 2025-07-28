import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FormKalkulasiScreen extends StatefulWidget {
  final Map<dynamic, dynamic> pelanggan;
  const FormKalkulasiScreen({required this.pelanggan, Key? key}) : super(key: key);

  @override
  State<FormKalkulasiScreen> createState() => _FormKalkulasiScreenState();
}

class _FormKalkulasiScreenState extends State<FormKalkulasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _standBaruController = TextEditingController();
  bool _loading = false;
  int _kubikasi = 0;
  int _tagihan = 0;

  int _toInt(dynamic value) => (value ?? 0).toInt();

  String _getJenisTarif() {
    return widget.pelanggan['tarif_cater']?.toString().split('_').first ?? 'P1';
  }

  @override
  void initState() {
    super.initState();
    _standBaruController.text = _toInt(widget.pelanggan['stand_baru']).toString();
    _hitungKubikasi();
  }

  @override
  void dispose() {
    _standBaruController.dispose();
    super.dispose();
  }

  Future<int> _hitungTagihanBertingkat(int pemakaian, String jenisTarif) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('tarif/$jenisTarif').get();
      if (!snapshot.exists) return pemakaian * 9000;
      
      final tarif = Map<String, dynamic>.from(snapshot.value as Map);
      int total = 0;
      int sisa = pemakaian;
      
      for (var i = 1; i <= 3; i++) {
        final golongan = tarif['golongan$i'];
        if (golongan == null) break;
        
        final min = _toInt(golongan['min']);
        final max = _toInt(golongan['max']);
        final harga = _toInt(golongan['harga']);
        
        if (sisa <= 0) break;
        
        final range = max - min;
        final volume = sisa > range ? range : sisa;
        total += volume * harga;
        sisa -= volume;
      }
      
      return total;
    } catch (e) {
      print('Error calculating tariff: $e');
      return pemakaian * 9000;
    }
  }

  Future<void> _hitungKubikasi() async {
    final standAwal = _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal']);
    final standBaru = int.tryParse(_standBaruController.text) ?? standAwal;
    final pemakaian = standBaru - standAwal;
    final jenisTarif = _getJenisTarif();
    
    final tagihan = await _hitungTagihanBertingkat(pemakaian, jenisTarif);

    setState(() {
      _kubikasi = pemakaian;
      _tagihan = tagihan;
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final standAwal = _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal']);
    final standBaru = int.tryParse(_standBaruController.text) ?? 0;
    final timestamp = DateTime.now();

    try {
      // Update customer data
      await FirebaseDatabase.instance
          .ref('pelanggan/${widget.pelanggan['id']}')
          .update({
            'stand_awal': standAwal,
            'stand_baru': standBaru,
            'kubikasi': _kubikasi,
            'tagihan': _tagihan,
            'tanggal_catat': timestamp.toIso8601String(),
          });

      // Add to history
      await FirebaseDatabase.instance
          .ref('histori/${widget.pelanggan['id']}_${timestamp.millisecondsSinceEpoch}')
          .set({
            'tanggal': timestamp.toIso8601String(),
            'stand_awal': standAwal,
            'stand_baru': standBaru,
            'kubikasi': _kubikasi,
            'tagihan': _tagihan,
            'pelanggan_id': widget.pelanggan['id'],
            'tarif': _getJenisTarif(),
          });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Stand Baru')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      widget.pelanggan['nama'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text("ID: ${widget.pelanggan['id']}"),
                    Text("Tarif: ${_getJenisTarif()}"),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      initialValue: _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal']).toString(),
                      decoration: InputDecoration(labelText: 'Stand Lama'),
                      enabled: false,
                    ),
                    
                    TextFormField(
                      controller: _standBaruController,
                      decoration: InputDecoration(labelText: 'Stand Baru'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _hitungKubikasi(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Harus diisi';
                        final newValue = int.tryParse(value);
                        if (newValue == null) return 'Harus angka';
                        if (newValue <= _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal'])) {
                          return 'Stand baru harus lebih besar';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RINCIAN TAGIHAN', style: TextStyle(fontWeight: FontWeight.bold)),
                            Divider(),
                            _buildDetailRow('Pemakaian', '$_kubikasi m³'),
                            _buildDetailRow('Tarif', _getTarifText(_getJenisTarif())),
                            Divider(),
                            _buildDetailRow('Total Tagihan', 'Rp $_tagihan', isBold: true),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _simpan,
                      child: Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getTarifText(String jenisTarif) {
    switch (jenisTarif) {
      case 'P1': return 'Rp 8.000-15.000/m³ (Tiered)';
      case 'R1': return 'Rp 5.000-9.000/m³ (Tiered)';
      case 'S1': return 'Rp 6.000-11.000/m³ (Tiered)';
      default: return 'Rp 9.000/m³ (Default)';
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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