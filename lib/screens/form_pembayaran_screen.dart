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
  bool _isLoading = false;

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
    
    setState(() {
      _isLoading = true;
    });

    final pembayaran = int.tryParse(_pembayaranController.text) ?? 0;
    int terhutangBaru = widget.totalTagihan - pembayaran;
    if (terhutangBaru < 0) terhutangBaru = 0;

    try {
      // Validasi stand meter
      if (widget.standBaru < widget.standAwal) {
        throw Exception('Stand baru tidak boleh kurang dari stand awal');
      }

      // Simpan histori pembayaran
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await FirebaseDatabase.instance
          .ref('pembayaran/${widget.pelangganId}_$timestamp')
          .set({
        'pelanggan_id': widget.pelangganId,
        'pembayaran': pembayaran,
        'tanggal': DateTime.now().toIso8601String(),
        'total_tagihan': widget.totalTagihan,
        'terhutang': terhutangBaru,
        'stand_awal': widget.standAwal,
        'stand_baru': widget.standBaru,
      });

      // Update data pelanggan
      await FirebaseDatabase.instance
          .ref('pelanggan/${widget.pelangganId}')
          .update({
        'stand_awal': widget.standAwal,
        'stand_baru': widget.standBaru,
        'kubikasi': widget.standBaru - widget.standAwal,
        'terhutang': terhutangBaru,
        'tanggal_catat': widget.tanggalCatat,
        'terakhir_update': ServerValue.timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil disimpan!')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              color: Colors.blue,
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
                          'FORM PEMBAYARAN',
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
                              // Informasi Meteran Section
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.yellow[300]!, width: 2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informasi Meteran',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildInfoRow('Stand Awal:', widget.standAwal.toString()),
                                      SizedBox(height: 8),
                                      _buildInfoRow('Stand Baru:', widget.standBaru.toString()),
                                      SizedBox(height: 8),
                                      _buildInfoRow('Pemakaian:', '${widget.standBaru - widget.standAwal}'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Informasi Tagihan Section
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.yellow[300]!, width: 2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informasi Tagihan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildInfoRow('Total Tagihan', _formatCurrency(widget.totalTagihan)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              
                              // Input Nominal Pembayaran
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.yellow[400]!, width: 2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _pembayaranController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan Nominal Bayar',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
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
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[600],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '\$',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Sisa Tagihan Display
                              if (_sisa != null) ...[
                                SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _sisa! > 0 ? Colors.orange[50] : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _sisa! > 0 ? Colors.orange[300]! : Colors.green[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: _buildInfoRow(
                                      _sisa! > 0 ? 'Sisa Tagihan:' : 'Lunas:',
                                      _formatCurrency(_sisa!),
                                      color: _sisa! > 0 ? Colors.orange[700] : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _simpanPembayaran,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  color: Color(0xFF2196F3),
                                )
                              : Text(
                                  'SIMPAN PEMBAYARAN',
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.blue[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}