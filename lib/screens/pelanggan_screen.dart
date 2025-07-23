// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'detail_pelanggan_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PelangganScreen extends StatefulWidget {
  @override
  _PelangganScreenState createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  List<Map<String, String>> pelangganList = [
    {
      'id': 'P1001A',
      'nama': 'Budi Santoso',
      'alamat': 'Padukuhan A',
      'tanggal': '22 Juli 2025',
      'avatar': '👨'
    },
    {
      'id': 'R1002A',
      'nama': 'Siti Aminah',
      'alamat': 'Padukuhan B',
      'tanggal': '22 Juli 2025',
      'avatar': '👩'
    },
    {
      'id': 'R1003A',
      'nama': 'Andi Wijaya',
      'alamat': 'Padukuhan C',
      'tanggal': '22 Juli 2025',
      'avatar': '👱'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildPelangganList()),
            _buildWave(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade300],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Spacer(),
          Text(
            'PELANGGAN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Spacer(),
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset('images/uns.jpg', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _buildPelangganList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80),
      itemCount: pelangganList.length,
      itemBuilder: (context, index) {
        final pelanggan = pelangganList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPelangganScreen(pelanggan: pelanggan),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.yellow[200],
                  radius: 30,
                  child: Text(pelanggan['avatar'] ?? '👤', style: TextStyle(fontSize: 30)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelanggan['nama'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                      ),
                      SizedBox(height: 4),
                      Text('PADUKUHAN : ${pelanggan['alamat'] ?? ''}', style: TextStyle(fontSize: 13)),
                      Text('TANGGAL : ${pelanggan['tanggal'] ?? ''}', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(pelanggan['id'] ?? '', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _tambahPelanggan(data: pelanggan, index: index);
                      },
                      child: Icon(Icons.edit, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWave() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 60,
        color: Colors.yellow[100],
      ),
    );
  }

  void _tambahPelanggan({Map<String, String>? data, int? index}) {
    final idController = TextEditingController(text: data?['id'] ?? '');
    final namaController = TextEditingController(text: data?['nama'] ?? '');
    final alamatController = TextEditingController(text: data?['alamat'] ?? '');
    final tanggalController = TextEditingController(text: data?['tanggal'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: idController, decoration: InputDecoration(labelText: 'ID')),
              TextField(controller: namaController, decoration: InputDecoration(labelText: 'Nama')),
              TextField(controller: alamatController, decoration: InputDecoration(labelText: 'Padukuhan')),
              TextField(controller: tanggalController, decoration: InputDecoration(labelText: 'Tanggal')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final newData = {
                  'id': idController.text,
                  'nama': namaController.text,
                  'alamat': alamatController.text,
                  'tanggal': tanggalController.text,
                  'avatar': data?['avatar'] ?? '👤',
                };
                if (index != null) {
                  pelangganList[index] = newData;
                } else {
                  pelangganList.add(newData);
                }
              });
              Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.5);

    path.quadraticBezierTo(
      size.width * 0.25, 0,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height,
      size.width, size.height * 0.5,
    );

    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

