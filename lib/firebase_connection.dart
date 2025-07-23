// lib/firebase_connection.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase berhasil diinisialisasi');
  }
}
