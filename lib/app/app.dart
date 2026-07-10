import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../features/trips/screens/home_screen.dart';

class RideBoundApp extends StatelessWidget {
  const RideBoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideBound',
      debugShowCheckedModeBanner: false,

      // Uses the theme defined in lib/theme/theme.dart
      theme: AppTheme.darkTheme,

      home: const HomeScreen(),
    );
  }
}