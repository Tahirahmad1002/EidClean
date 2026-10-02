import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const EidCleanApp(),
    ),
  );
}

class EidCleanApp extends StatelessWidget {
  const EidCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAF8),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );

    return MaterialApp(
      title: 'EidClean',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      home: const SplashScreen(),
    );
  }
}