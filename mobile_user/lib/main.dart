import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeridianHealthApp());
}

class MeridianHealthApp extends StatelessWidget {
  const MeridianHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meridian Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052CC),
          primary: const Color(0xFF0052CC),
          surface: const Color(0xFFF7F9FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const AuthGate(),
    );
  }
}
