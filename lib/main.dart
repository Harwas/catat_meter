import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Aktifkan offline persistence
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  // Sinkronkan data penting agar selalu ada di cache
  FirebaseDatabase.instance.ref("pelanggan").keepSynced(true);
  FirebaseDatabase.instance.ref("pencatatan").keepSynced(true);
  FirebaseDatabase.instance.ref("keuangan").keepSynced(true);

  // Pantau status koneksi Firebase
  FirebaseDatabase.instance.ref(".info/connected").onValue.listen((event) {
    final connected = event.snapshot.value as bool? ?? false;
    debugPrint("Koneksi Firebase: ${connected ? "Online" : "Offline"}");
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catat Meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
