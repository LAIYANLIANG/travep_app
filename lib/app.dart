import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/presentation/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58),
          brightness: Brightness.light, 
        ),
      ),
      // Home Page Dashboard Routing
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}
