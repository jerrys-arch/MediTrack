import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/notification_service.dart';

import 'providers/auth_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/symptom_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/emergency_provider.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Load saved tokens from storage
    await auth.loadTokens();

    // If we have a refresh token, try to get a fresh access token
    // This handles the case where the access token expired while app was closed
    if (auth.refreshToken != null) {
      await auth.refreshAccessToken();
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      return const HomeDashboardScreen();
    }
    return const WelcomeScreen();
  }
}