import 'package:flutter/material.dart';
import 'form_pembayaran_screen.dart';

class FormKalkulasiScreen extends StatefulWidget {
  final Map<dynamic, dynamic> pelanggan;
  const FormKalkulasiScreen({required this.pelanggan, Key? key}) : super(key: key);

  @override
  State<FormKalkulasiScreen> createState() => _FormKalkulasiScreenState();
}

class _FormKalkulasiScreenState extends State<FormKalkulasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _standBaruController = TextEditingController();
  int _kubikasi = 0;
  int _tagihan = 0;
  int _terhutangSebelumnya = 0;
  int _standAwal = 0;

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;

  String _getJenisTarif() {
    return widget.pelanggan['tarif']?.toString().split('_').first ?? 'P1';
  }

  int _getHargaPerKubik(String jenisTarif) {
    switch (jenisTarif) {
      case 'R1':
        return 5000;
      case 'S1':
        return 6000;
      case 'P1':
      default:
        return 7000;
    }
  }

  @override
  void initState() {
    super.initState();
    _standAwal = _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal']);
    _standBaruController.text = _standAwal.toString();
    _terhutangSebelumnya = _toInt(widget.pelanggan['terhutang']);
    _hitungKubikasi();
  }

  void _hitungKubikasi() {
    final standBaru = int.tryParse(_standBaruController.text) ?? _standAwal;
    final pemakaian = standBaru - _standAwal;
    final harga = _getHargaPerKubik(_getJenisTarif());
    final tagihanBaru = pemakaian * harga;
    final totalTagihan = tagihanBaru + _terhutangSebelumnya;

    setState(() {
      _kubikasi = pemakaian;
      _tagihan = totalTagihan;
    });
  }

  void _lanjutPembayaran() {
    if (!_formKey.currentState!.validate()) return;
    final standBaru = int.tryParse(_standBaruController.text) ?? _standAwal;
    final tanggalCatat = DateTime.now().toIso8601String();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FormPembayaranScreen(
          pelangganId: widget.pelanggan['id'],
          standAwal: _standAwal,
          standBaru: standBaru,
          tanggalCatat: tanggalCatat,
          totalTagihan: _tagihan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kalkulasi Tagihan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(widget.pelanggan['nama'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("ID: ${widget.pelanggan['id']}"),
              Text("Tarif: ${_getJenisTarif()}"),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _standAwal.toString(),
                decoration: InputDecoration(labelText: 'Stand Awal'),
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
                  if (newValue <= _standAwal) {
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
                      _buildDetailRow('Tarif', 'Rp ${_getHargaPerKubik(_getJenisTarif())}/m³'),
                      _buildDetailRow('Terhutang Sebelumnya', 'Rp $_terhutangSebelumnya'),
                      Divider(),
                      _buildDetailRow('Total Tagihan', 'Rp $_tagihan', isBold: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _lanjutPembayaran,
                child: Text('Lanjut ke Pembayaran'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
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
          Text(
            value,
            style: isBold ? TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}