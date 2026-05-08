import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';
import 'overlay_widget.dart';

/// Punto de entrada principal de la app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CronometroApp());
}

/// Punto de entrada de la ventana flotante (separado del main)
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    ),
    home: const OverlayWidget(),
  ));
}

class CronometroApp extends StatelessWidget {
  const CronometroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronómetro Flotante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a73e8),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
