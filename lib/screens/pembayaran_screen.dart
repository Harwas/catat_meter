import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PembayaranScreen extends StatefulWidget {
  final String pelangganId;
  final String pelangganNama;
  final int tagihan;
  final int kubikasi;
  final int standAwal;
  final int standBaru;

  const PembayaranScreen({
    required this.pelangganId,
    required this.pelangganNama,
    required this.tagihan,
    required this.kubikasi,
    required this.standAwal,
    required this.standBaru,
    Key? key,
  }) : super(key: key);

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final _nominalController = TextEditingController();
  bool _loading = false;
  bool _paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    _nominalController.text = widget.tagihan.toString();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _prosesPembayaran() async {
    final nominal = int.tryParse(_nominalController.text) ?? 0;
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final pembayaranData = {
        'tanggal': now.toIso8601String(),
        'pelanggan_id': widget.pelangganId,
        'nominal': nominal,
        'tagihan': widget.tagihan,
        'kubikasi': widget.kubikasi,
        'stand_awal': widget.standAwal,
        'stand_baru': widget.standBaru,
      };

      // Save payment record
      await FirebaseDatabase.instance
          .ref('pembayaran/${now.millisecondsSinceEpoch}')
          .set(pembayaranData);

      // Update customer's payment status
      final pelangganRef = FirebaseDatabase.instance.ref('pelanggan/${widget.pelangganId}');
      final snapshot = await pelangganRef.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final dibayar = (data['dibayar'] ?? 0).toInt();
        final terhutang = (data['terhutang'] ?? 0).toInt();
        
        await pelangganRef.update({
          'dibayar': dibayar + nominal,
          'terhutang': terhutang - nominal,
        });
      }

      setState(() => _paymentSuccess = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran berhasil dicatat')),
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
      appBar: AppBar(title: Text('Pembayaran')),
      body: _paymentSuccess
          ? _buildSuccessScreen()
          : _loading
              ? Center(child: CircularProgressIndicator())
              : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pelangganNama,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("ID: ${widget.pelangganId}"),
          SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPaymentRow('Stand Awal', '${widget.standAwal} m³'),
                  _buildPaymentRow('Stand Baru', '${widget.standBaru} m³'),
                  _buildPaymentRow('Pemakaian', '${widget.kubikasi} m³'),
                  Divider(),
                  _buildPaymentRow('Total Tagihan', 'Rp ${widget.tagihan}', isBold: true),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          TextFormField(
            controller: _nominalController,
            decoration: InputDecoration(
              labelText: 'Nominal Pembayaran (Rp)',
              border: OutlineInputBorder(),
              suffixText: 'Rp',
            ),
            keyboardType: TextInputType.number,
          ),
          
          Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _prosesPembayaran,
                  child: Text('Konfirmasi Pembayaran'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 16),
          Text(
            'Pembayaran Berhasil!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Rp ${_nominalController.text} telah dibayarkan'),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
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