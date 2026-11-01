import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase adaptif (Web menggunakan options, Mobile menggunakan google-services.json)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCH4vAecvTKrulFtyALjuf0jFJkMaVdE3I",
        authDomain: "kostku-a77e1.firebaseapp.com",
        projectId: "kostku-a77e1",
        storageBucket: "kostku-a77e1.firebasestorage.app",
        messagingSenderId: "1020060343523",
        appId: "1:1020060343523:web:855f246f41f0674896f9d6",
      ),
    );
  } else {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Fallback jika google-services.json memerlukan explicit options
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB_xGXse_rU9xOEGOh9c9cni4CqElp2qSY",
          appId: "1:1020060343523:android:4ce1d3b8a6381b3f96f9d6",
          messagingSenderId: "1020060343523",
          projectId: "kostku-a77e1",
          storageBucket: "kostku-a77e1.firebasestorage.app",
        ),
      );
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF2B3674);
    const accentIndigo = Color(0xFF4318FF);
    const scaffoldBg = Color(0xFFF8F9FA);

    return MaterialApp(
      title: 'KostKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentIndigo,
          primary: primaryNavy,
          secondary: accentIndigo,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: primaryNavy),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
