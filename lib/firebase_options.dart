// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de configuración predeterminadas para este proyecto Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // De acuerdo a la plataforma, se devuelven las opciones correspondientes
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para Windows - '
          'crea tu configuración app con Firebase CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para Linux - '
          'crea tu configuración app con Firebase CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para esta plataforma.',
        );
    }
  }

  // Configuración para Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzlj4APqi5S58nFtE52Da-fYBOHA2MhaM',
    appId: '1:448618578101:web:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'memorial-app-flutter',
    authDomain: 'memorial-app-flutter.firebaseapp.com',
    storageBucket: 'memorial-app-flutter.appspot.com',
    measurementId: 'G-C79ZEN0LS1',
  );

  // Configuración para Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALkflLM36e7sANFqoMKONTXRHlFTYTMsE',
    appId: '1:448618578101:android:047deab1fd62e945ac3efc',
    messagingSenderId: '448618578101',
    projectId: 'memorial-app-flutter',
    storageBucket: 'memorial-app-flutter.appspot.com',
  );

  // Configuración para iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxVdLsGQFWCBrG9fDwQBTjJsGqOCALPAM',
    appId: '1:448618578101:ios:ee1e4e2f6a3dd61aac3efc',
    messagingSenderId: '448618578101',
    projectId: 'memorial-app-flutter',
    storageBucket: 'memorial-app-flutter.appspot.com',
    iosClientId: '448618578101-c3rlsi8nv6erhvsqqq0i92dsdmd0lpbg.apps.googleusercontent.com',
    iosBundleId: 'com.example.memorialapp',
  );

  // Configuración para macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxVdLsGQFWCBrG9fDwQBTjJsGqOCALPAM',
    appId: '1:448618578101:ios:ee1e4e2f6a3dd61aac3efc',
    messagingSenderId: '448618578101',
    projectId: 'memorial-app-flutter',
    storageBucket: 'memorial-app-flutter.appspot.com',
    iosClientId: '448618578101-c3rlsi8nv6erhvsqqq0i92dsdmd0lpbg.apps.googleusercontent.com',
    iosBundleId: 'com.example.memorialapp',
  );
}