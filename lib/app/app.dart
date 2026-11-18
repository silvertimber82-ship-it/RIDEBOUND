
import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import 'splash_screen.dart';

class RideBoundApp extends StatelessWidget {
  const RideBoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideBound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return SafeArea(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
