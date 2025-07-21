import 'package:catat_meter/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Data dummy pelanggan
  final Map<String, dynamic> dummyData = {
    'id': 'P001',
    'nama': 'Roy Harwa',
    'qr_code': 'QR123456',
    'tarif': 1500,
    'catatan_meter': 'Awal bulan Juli',
    'alamat': 'Desa Maju Jaya RT 03',
    'no_hp': '081234567890',
    'stan_awal': 120,
    'foto': 'https://example.com/foto.jpg',
  };

  // Kirim data ke Firebase
  final dbRef = FirebaseDatabase.instance.ref().child('pelanggan/P001');

  try {
    await dbRef.set(dummyData);
    debugPrint('✅ Data dummy berhasil dikirim ke Firebase');
  } catch (e) {
    debugPrint('❌ Gagal mengirim data: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat Meter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: const Center(
        child: Text(
          'Data Dummy telah dikirim ke Firebase!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
