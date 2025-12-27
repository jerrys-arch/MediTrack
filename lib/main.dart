import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔹 Import all providers
import 'providers/auth_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/symptom_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/emergency_provider.dart';

// 🔹 Import screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediTrack',
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const SignUpScreen(),
          '/home': (context) => const HomeDashboardScreen(),
        },
      ),
    );
  }
}

/// 🔹 Decides which screen to show based on login state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.accessToken != null) {
      return const HomeDashboardScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}
