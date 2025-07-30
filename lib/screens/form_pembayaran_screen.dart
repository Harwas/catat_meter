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

      // Ambil data pelanggan terlebih dahulu
      final snapshot = await FirebaseDatabase.instance
          .ref('pelanggan/${widget.pelangganId}')
          .once();

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final bool isFirstTime = data['stand_awal'] == null;

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
        'stand_awal': isFirstTime ? 0 : data['stand_awal'],
        'stand_baru': widget.standBaru,
      });

      // Update data pelanggan
      await FirebaseDatabase.instance
          .ref('pelanggan/${widget.pelangganId}')
          .update({
        'stand_awal': isFirstTime ? 0 : data['stand_awal'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Pembayaran'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Meteran',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stand Awal:'),
                          Text(widget.standAwal.toString()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stand Baru:'),
                          Text(widget.standBaru.toString()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pemakaian:'),
                          Text('${widget.standBaru - widget.standAwal}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Tagihan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tagihan:'),
                          Text(
                            'Rp ${widget.totalTagihan}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pembayaranController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Pembayaran',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  suffixIcon: Icon(Icons.attach_money),
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
              const SizedBox(height: 16),
              if (_sisa != null)
                Card(
                  color: _sisa! > 0 ? Colors.orange[50] : Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _sisa! > 0 ? 'Sisa Tagihan:' : 'Lunas:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rp $_sisa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _sisa! > 0 ? Colors.orange[800] : Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPembayaran,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'SIMPAN PEMBAYARAN',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}