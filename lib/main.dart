import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart'; // 🔹 Import Home Screen
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediTrack',
      home: const WelcomeScreen(), // 🔹 Still first screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
        '/home': (context) => const HomeDashboardScreen(), // 🔹 Added Home Dashboard
      },
    );
  }
}
