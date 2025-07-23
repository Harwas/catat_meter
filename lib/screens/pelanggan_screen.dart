import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'detail_pelanggan_screen.dart';
import 'tambah_pelanggan_screen.dart';

class PelangganScreen extends StatefulWidget {
  @override
  _PelangganScreenState createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  List<Map<String, String>> pelangganList = [];

  @override
  void initState() {
    super.initState();
    _loadPelangganFromFirebase();
  }

  Future<void> _loadPelangganFromFirebase() async {
    final dbRef = FirebaseDatabase.instance.ref('pelanggan');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map?;
      pelangganList = [];
      if (data != null) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value);
          pelangganList.add(map.map((k, v) => MapEntry(k, v.toString())));
        });
      }
      setState(() {});
    }
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke screen tambah pelanggan
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TambahPelangganScreen()),
          );
          if (result != null) {
            // Jika ada data baru, reload dari Firebase
            _loadPelangganFromFirebase();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Pelanggan',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
    if (pelangganList.isEmpty) {
      return Center(child: Text('Belum ada data pelanggan.'));
    }
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