import 'package:flutter/material.dart';
import 'package:nexconnect/core/theme/app_theme.dart';
import 'package:nexconnect/features/auth/login_page.dart';
import 'package:nexconnect/features/auth/splash_page.dart';
import 'package:nexconnect/features/dashboard/dashboard_page.dart';

void main() {
  runApp(const PBNApp());
}

class PBNApp extends StatelessWidget {
  const PBNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prime Business Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
