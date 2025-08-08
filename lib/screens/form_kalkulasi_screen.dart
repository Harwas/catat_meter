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

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header Section with Blue Background
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    // Title
                    Expanded(
                      child: Center(
                        child: Text(
                          'KALKULASI TAGIHAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Logo/Icon
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEB3B),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/PROFIL.PNG',
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                          // Menangani error jika gambar tidak ditemukan
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      
                      // Main Card Container
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              Text(
                                widget.pelanggan['nama'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Customer Details
                              _buildInfoField('ID', widget.pelanggan['id']?.toString() ?? 'R30001D'),
                              SizedBox(height: 12),
                              _buildInfoField('Tarif_nama', _getJenisTarif()),
                              SizedBox(height: 12),
                              _buildInfoField('Stand Awal', _standAwal.toString()),
                              SizedBox(height: 16),
                              
                              // Stand Baru Input
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stand Baru',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: _standBaruController,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.blue[300]!),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.blue[300]!),
                                      ),
                                    ),
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
                                ],
                              ),
                              SizedBox(height: 24),
                              
                              // Rincian Tagihan Card
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.yellow[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.yellow[300]!, width: 2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rincian Tagihan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildBillingRow('Pemakaian', '$_kubikasi m³'),
                                      SizedBox(height: 8),
                                      _buildBillingRow('Tarif', '${_formatCurrency(_getHargaPerKubik(_getJenisTarif()))}/m³'),
                                      SizedBox(height: 8),
                                      _buildBillingRow('Terhutang Sebelumnya', _formatCurrency(_terhutangSebelumnya)),
                                      SizedBox(height: 12),
                                      Divider(color: Colors.grey[400], thickness: 1),
                                      SizedBox(height: 8),
                                      _buildBillingRow('Total Tagihan', _formatCurrency(_tagihan), isBold: true),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _lanjutPembayaran,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Lanjut ke Pembayaran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Navigation Bar
          
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Divider(color: Colors.blue[200], height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}