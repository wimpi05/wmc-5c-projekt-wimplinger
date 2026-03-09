import 'package:flutter/material.dart';
import 'package:frontend/providers/ride_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:provider/provider.dart';
void main() {
  // Sicherstellen, dass die Flutter-Bindings initialisiert sind
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Der RideProvider lädt beim Start sofort alle Fahrten
        ChangeNotifierProvider(
          create: (_) => RideProvider()..fetchRides(),
        ),
        // Der UserProvider verwaltet das Profil (Konzept 5.5)
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loginDefaultUser(),
        ),
        // Der ThemeProvider für deine 5 Theme-Varianten
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const RideLogApp(),
    ),
  );
}

class RideLogApp extends StatelessWidget {
  const RideLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wir hören auf den ThemeProvider für Echtzeit-Wechsel
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RideLog',
      debugShowCheckedModeBanner: false,
      
      // Theme-Konfiguration basierend auf deinem Seed-Color Konzept
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      // Start-Screen der App
      home: const HomeScreen(),
    );
  }
}