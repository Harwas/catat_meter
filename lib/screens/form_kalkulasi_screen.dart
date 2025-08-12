import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_pembayaran_screen.dart';

class FormKalkulasiScreen extends StatefulWidget {
  final Map<String, dynamic> pelanggan; // Ubah dari Map<dynamic, dynamic> ke Map<String, dynamic>
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
  int _hargaPerKubik = 0;
  String _jenisTarif = '';
  bool _isLoadingTarif = true;

  // Ganti Firebase Realtime Database dengan Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();
    // Enable offline persistence untuk Firestore (jika belum dilakukan di main.dart)
    _enableOfflinePersistence();
    
    _standAwal = _toInt(widget.pelanggan['stand_baru'] ?? widget.pelanggan['stand_awal']);
    _standBaruController.text = _standAwal.toString();
    _terhutangSebelumnya = _toInt(widget.pelanggan['terhutang']);

    _loadTarif().then((_) {
      _hitungKubikasi();
    });
  }

  // Method untuk mengaktifkan offline persistence
  Future<void> _enableOfflinePersistence() async {
    try {
      await _firestore.enablePersistence();
    } catch (e) {
      print('Could not enable offline persistence: $e');
    }
  }

  Future<void> _loadTarif() async {
    setState(() => _isLoadingTarif = true);
    
    try {
      String? tarifKey = widget.pelanggan['tarif_key'];

      if (tarifKey != null && tarifKey.isNotEmpty) {
        // Ambil tarif sesuai key menggunakan Firestore
        final docSnapshot = await _firestore
            .collection('tarif')
            .doc(tarifKey)
            .get(GetOptions(source: Source.serverAndCache)); // Coba server dulu, fallback ke cache
        
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          setState(() {
            _hargaPerKubik = _toInt(data['harga']);
            _jenisTarif = data['nama']?.toString() ?? '';
            _isLoadingTarif = false;
          });
          _showDataSource(docSnapshot.metadata.isFromCache);
          return;
        }
      }

      // Kalau tidak ada tarif_key atau datanya tidak ditemukan → ambil harga default dari tarif pertama
      final querySnapshot = await _firestore
          .collection('tarif')
          .limit(1)
          .get(GetOptions(source: Source.serverAndCache));
      
      if (querySnapshot.docs.isNotEmpty) {
        final firstTarif = querySnapshot.docs.first.data();
        setState(() {
          _hargaPerKubik = _toInt(firstTarif['harga']);
          _jenisTarif = firstTarif['nama']?.toString() ?? '';
          _isLoadingTarif = false;
        });
        _showDataSource(querySnapshot.metadata.isFromCache);
      } else {
        // Jika tidak ada data tarif sama sekali
        setState(() {
          _hargaPerKubik = 0;
          _jenisTarif = 'Tarif tidak tersedia';
          _isLoadingTarif = false;
        });
        _showConnectionStatus('Tidak ada data tarif tersedia', Colors.red);
      }
    } catch (e) {
      print('Error loading tarif: $e');
      setState(() {
        _hargaPerKubik = 0;
        _jenisTarif = 'Error loading tarif';
        _isLoadingTarif = false;
      });
      _showConnectionStatus('Error loading tarif', Colors.red);
    }
  }

  // Method untuk menampilkan sumber data (cache atau server)
  void _showDataSource(bool isFromCache) {
    if (isFromCache) {
      print('Tarif data dari cache (offline)');
      _showConnectionStatus('Offline - Data tarif dari cache', Colors.orange);
    } else {
      print('Tarif data dari server (online)');
      _showConnectionStatus('Online - Data tarif terbaru', Colors.green);
    }
  }

  // Method untuk menampilkan status koneksi
  void _showConnectionStatus(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Method untuk refresh tarif secara manual
  Future<void> _refreshTarif() async {
    await _loadTarif();
    _hitungKubikasi();
  }

  void _hitungKubikasi() {
    final standBaru = int.tryParse(_standBaruController.text) ?? _standAwal;
    final pemakaian = standBaru - _standAwal;
    final tagihanBaru = pemakaian * _hargaPerKubik;
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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
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
                    // Tambahkan refresh button untuk tarif
                    IconButton(
                      onPressed: _isLoadingTarif ? null : _refreshTarif,
                      icon: _isLoadingTarif 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.refresh, color: Colors.white, size: 24),
                      tooltip: 'Refresh Tarif',
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
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
                              Text(
                                widget.pelanggan['nama'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildInfoField('ID', widget.pelanggan['id']?.toString() ?? ''),
                              SizedBox(height: 12),
                              _buildInfoField('Tarif', _isLoadingTarif ? 'Memuat...' : _jenisTarif),
                              SizedBox(height: 12),
                              _buildInfoField('Stand Awal', _standAwal.toString()),
                              SizedBox(height: 16),
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
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => _hitungKubikasi(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Harus diisi';
                                      final newValue = int.tryParse(value);
                                      if (newValue == null) return 'Harus angka';
                                      if (newValue <= _standAwal) return 'Stand baru harus lebih besar';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rincian Tagihan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                          if (_isLoadingTarif)
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      _buildBillingRow('Pemakaian', '$_kubikasi m³'),
                                      SizedBox(height: 8),
                                      _buildBillingRow('Tarif', '${_formatCurrency(_hargaPerKubik)}/m³'),
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
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoadingTarif ? null : _lanjutPembayaran,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoadingTarif ? Colors.grey : Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoadingTarif
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
                                      'Memuat Tarif...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
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
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.blue[600], fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        SizedBox(height: 8),
        Divider(color: Colors.blue[200], height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.blue[600], fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.blue[600], fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}