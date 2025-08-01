// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDiqrVUGdO2D6HSEU0KTkNvjPW0m91inNk',
    appId: '1:719421565871:web:38c5304796395c802e5d5a',
    messagingSenderId: '719421565871',
    projectId: 'catat-meter-62d87',
    authDomain: 'catat-meter-62d87.firebaseapp.com',
    databaseURL: 'https://catat-meter-62d87-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'catat-meter-62d87.firebasestorage.app',
    measurementId: 'G-0G3066YWHE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfDQeWrkBFsFS17aJO8rfydPi1cPr0DrY',
    appId: '1:719421565871:android:2daacdfa413b0e1c2e5d5a',
    messagingSenderId: '719421565871',
    projectId: 'catat-meter-62d87',
    databaseURL: 'https://catat-meter-62d87-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'catat-meter-62d87.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMfPA3wLzgThH6hCUW1uk7q4SaxMPwS6I',
    appId: '1:719421565871:ios:e4ec76ea861c60e12e5d5a',
    messagingSenderId: '719421565871',
    projectId: 'catat-meter-62d87',
    databaseURL: 'https://catat-meter-62d87-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'catat-meter-62d87.firebasestorage.app',
    iosBundleId: 'com.example.catatMeter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAMfPA3wLzgThH6hCUW1uk7q4SaxMPwS6I',
    appId: '1:719421565871:ios:e4ec76ea861c60e12e5d5a',
    messagingSenderId: '719421565871',
    projectId: 'catat-meter-62d87',
    databaseURL: 'https://catat-meter-62d87-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'catat-meter-62d87.firebasestorage.app',
    iosBundleId: 'com.example.catatMeter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDiqrVUGdO2D6HSEU0KTkNvjPW0m91inNk',
    appId: '1:719421565871:web:a4be2750d0bf69e92e5d5a',
    messagingSenderId: '719421565871',
    projectId: 'catat-meter-62d87',
    authDomain: 'catat-meter-62d87.firebaseapp.com',
    databaseURL: 'https://catat-meter-62d87-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'catat-meter-62d87.firebasestorage.app',
    measurementId: 'G-CNHJKVMKKJ',
  );

}