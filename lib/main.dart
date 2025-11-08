// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArbolProvider()),
      ],
      child: MaterialApp(
        title: 'Memorial App',
        
        // CORREGIDO: Usar el tema unificado de AppTheme
        theme: AppTheme.lightTheme,
        
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}