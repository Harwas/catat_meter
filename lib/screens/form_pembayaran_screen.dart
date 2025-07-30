import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FormPembayaranScreen extends StatefulWidget {
  final String pelangganId;
  final int standAwal;
  final int standBaru;
  final String tanggalCatat;
  final int totalTagihan;

  const FormPembayaranScreen({
    Key? key,
    required this.pelangganId,
    required this.standAwal,
    required this.standBaru,
    required this.tanggalCatat,
    required this.totalTagihan,
  }) : super(key: key);

  @override
  State<FormPembayaranScreen> createState() => _FormPembayaranScreenState();
}

class _FormPembayaranScreenState extends State<FormPembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pembayaranController = TextEditingController();
  int? _sisa;

  @override
  void dispose() {
    _pembayaranController.dispose();
    super.dispose();
  }

  void _hitungSisa() {
    final pembayaran = int.tryParse(_pembayaranController.text) ?? 0;
    var sisa = widget.totalTagihan - pembayaran;
    if (sisa < 0) sisa = 0;
    setState(() {
      _sisa = sisa;
    });
  }

  Future<void> _simpanPembayaran() async {
    if (!_formKey.currentState!.validate()) return;
    final pembayaran = int.tryParse(_pembayaranController.text) ?? 0;
    int terhutangBaru = widget.totalTagihan - pembayaran;
    if (terhutangBaru < 0) terhutangBaru = 0;

    try {
      // Simpan histori pembayaran
      await FirebaseDatabase.instance
          .ref('pembayaran/${widget.pelangganId}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'pelanggan_id': widget.pelangganId,
        'pembayaran': pembayaran,
        'tanggal': DateTime.now().toIso8601String(),
        'total_tagihan': widget.totalTagihan,
        'terhutang': terhutangBaru,
      });

      // Update pelanggan: stand_awal di-overwrite oleh stand_baru, terhutang, tanggal_catat
      await FirebaseDatabase.instance
          .ref('pelanggan/${widget.pelangganId}')
          .update({
        'stand_awal': widget.standBaru, // overwrite
        'stand_baru': widget.standBaru,
        'terhutang': terhutangBaru,
        'tanggal_catat': widget.tanggalCatat,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran berhasil disimpan!')),
      );
      Navigator.popUntil(context, (route) => route.isFirst); // Kembali ke root
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Tagihan: Rp ${widget.totalTagihan}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              TextFormField(
                controller: _pembayaranController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Pembayaran',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pembayaran tidak boleh kosong';
                  }
                  final pembayaran = int.tryParse(value);
                  if (pembayaran == null) {
                    return 'Harus berupa angka';
                  }
                  if (pembayaran < 0) {
                    return 'Pembayaran tidak boleh negatif';
                  }
                  if (pembayaran > widget.totalTagihan) {
                    return 'Pembayaran melebihi tagihan';
                  }
                  return null;
                },
                onChanged: (_) => _hitungSisa(),
              ),
              SizedBox(height: 16),
              if (_sisa != null)
                Text('Sisa Tagihan (Terhutang): Rp ${_sisa!}', style: TextStyle(fontSize: 16)),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _simpanPembayaran,
                  child: Text('Simpan Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}