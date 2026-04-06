import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAid1tu1wnfEuMpo9dkS7cFb1f-xElquxo",
        authDomain: "alpenkamm-web.firebaseapp.com",
        projectId: "alpenkamm-web",
        storageBucket: "alpenkamm-web.firebasestorage.app",
        messagingSenderId: "781091560125",
        appId: "1:781091560125:web:d77cf50ba892d501bf35d4",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const AlpenkammApp());
}

class AlpenkammApp extends StatelessWidget {
  const AlpenkammApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpenkamm Bonus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF556B2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}