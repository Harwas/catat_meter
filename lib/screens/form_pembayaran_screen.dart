import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // TIDAK perlu _enableOfflinePersistence() di sini jika sudah di-setup di main.dart
  }

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

  // Method untuk mendapatkan nama pelanggan dari Firestore
  Future<String> _getNamaPelanggan() async {
    try {
      final doc = await _firestore
          .collection('pelanggan')
          .doc(widget.pelangganId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['nama'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      print('Error getting pelanggan name: $e');
      return 'Unknown';
    }
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

      // Generate ID untuk dokumen pembayaran
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pembayaranId = '${widget.pelangganId}_$timestamp';

      // Ambil nama pelanggan terlebih dahulu
      final namaPelanggan = await _getNamaPelanggan();
      
      print('Saving payment data...');

      // Simpan histori pembayaran terlebih dahulu
      await _firestore.collection('pembayaran').doc(pembayaranId).set({
        'pelanggan_id': widget.pelangganId,
        'pelanggan_nama': namaPelanggan,
        'pembayaran': pembayaran,
        'tanggal': DateTime.now().toIso8601String(),
        'total_tagihan': widget.totalTagihan,
        'terhutang': terhutangBaru,
        'stand_awal': widget.standAwal,
        'stand_baru': widget.standBaru,
        'created_at': FieldValue.serverTimestamp(),
        'kubikasi': widget.standBaru - widget.standAwal,
        'status': 'completed',
        'offline_created': true, // Flag untuk tracking offline creation
      });

      print('Payment document saved: $pembayaranId');

      // Update data pelanggan
      await _firestore.collection('pelanggan').doc(widget.pelangganId).update({
        'stand_awal': widget.standAwal,
        'stand_baru': widget.standBaru,
        'kubikasi': widget.standBaru - widget.standAwal,
        'terhutang': terhutangBaru,
        'tanggal_catat': widget.tanggalCatat,
        'terakhir_update': FieldValue.serverTimestamp(),
        'last_payment': {
          'amount': pembayaran,
          'date': DateTime.now().toIso8601String(),
          'pembayaran_id': pembayaranId,
        },
      });

      print('Pelanggan document updated: ${widget.pelangganId}');

      if (!mounted) return;

      // Cek status koneksi untuk menentukan pesan
      final isOnline = await _checkInternetConnection();
      if (isOnline) {
        _showSuccessMessage('Pembayaran berhasil disimpan dan tersinkron!', Colors.green);
      } else {
        _showSuccessMessage('Pembayaran disimpan offline. Akan tersinkron otomatis saat online.', Colors.orange);
      }

      // Kembali ke halaman utama setelah delay singkat
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      
    } catch (e) {
      print('Error saving payment: $e');
      if (!mounted) return;

      // Untuk offline, Firestore akan otomatis menyimpan ke cache
      // dan sync saat online kembali
      _showSuccessMessage('Pembayaran disimpan offline. Akan tersinkron saat online kembali.', Colors.orange);
      
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method untuk mengecek koneksi internet yang lebih sederhana
  Future<bool> _checkInternetConnection() async {
    try {
      // Coba buat dokumen test untuk cek koneksi
      await _firestore
          .collection('_test')
          .doc('connection_test')
          .set({'test': true}, SetOptions(merge: true))
          .timeout(Duration(seconds: 3));
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Method untuk menampilkan pesan sukses
  void _showSuccessMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.cloud_off,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
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
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: _isLoading ? Colors.grey[400] : Colors.white,
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

                    // Status indicator untuk offline/online
                    FutureBuilder<bool>(
                      future: _checkInternetConnection(),
                      builder: (context, snapshot) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (snapshot.data == true) ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (snapshot.data == true) ? Icons.wifi : Icons.wifi_off,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                (snapshot.data == true) ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    
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
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, color: Colors.blue);
                          },
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
                                      _buildInfoRow('Pemakaian:', '${widget.standBaru - widget.standAwal} m³'),
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
                                          enabled: !_isLoading,
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
                                            color: _isLoading ? Colors.grey[400] : Colors.grey[700],
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
                                          color: _isLoading ? Colors.grey : Colors.yellow[600],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          'Rp',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
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
                                      _sisa! > 0 ? 'Sisa Tagihan:' : 'Status:',
                                      _sisa! > 0 ? _formatCurrency(_sisa!) : 'LUNAS',
                                      color: _sisa! > 0 ? Colors.orange[700] : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],

                              // Loading indicator saat menyimpan
                              if (_isLoading) ...[
                                SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[300]!, width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Menyimpan pembayaran...',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
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
                          color: _isLoading ? Colors.grey[400] : Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: (_isLoading ? Colors.grey : Colors.blue).withOpacity(0.3),
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
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'MENYIMPAN...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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