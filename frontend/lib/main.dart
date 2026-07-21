import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const EpmsApp());
}

class EpmsApp extends StatelessWidget {
  const EpmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPMS Foundation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
