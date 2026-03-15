import 'package:flutter/material.dart';
import 'screens/standings_screen.dart';

void main() {
  runApp(const BasketballStatsApp());
}

class BasketballStatsApp extends StatelessWidget {
  const BasketballStatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Stats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFF1A1A2E),
        ),
      ),
      home: const StandingsScreen(),
    );
  }
}
