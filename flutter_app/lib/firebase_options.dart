// File generated for RESET AI - Firebase configuration
// Using provided Firebase project: reset-ai-gdg

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8',
    appId: '1:883561761358:web:9fa35d31d1019dbe48d11f',
    messagingSenderId: '883561761358',
    projectId: 'reset-ai-gdg',
    authDomain: 'reset-ai-gdg.firebaseapp.com',
    storageBucket: 'reset-ai-gdg.firebasestorage.app',
    measurementId: 'G-JY4LB76FHV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8',
    appId: '1:883561761358:android:reset_ai_android_app',
    messagingSenderId: '883561761358',
    projectId: 'reset-ai-gdg',
    storageBucket: 'reset-ai-gdg.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8',
    appId: '1:883561761358:ios:reset_ai_ios_app',
    messagingSenderId: '883561761358',
    projectId: 'reset-ai-gdg',
    storageBucket: 'reset-ai-gdg.firebasestorage.app',
    iosBundleId: 'com.resetai.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8',
    appId: '1:883561761358:macos:reset_ai_macos_app',
    messagingSenderId: '883561761358',
    projectId: 'reset-ai-gdg',
    storageBucket: 'reset-ai-gdg.firebasestorage.app',
    iosBundleId: 'com.resetai.app.macos',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8',
    appId: '1:883561761358:web:9fa35d31d1019dbe48d11f',
    messagingSenderId: '883561761358',
    projectId: 'reset-ai-gdg',
    authDomain: 'reset-ai-gdg.firebaseapp.com',
    storageBucket: 'reset-ai-gdg.firebasestorage.app',
    measurementId: 'G-JY4LB76FHV',
  );
}
