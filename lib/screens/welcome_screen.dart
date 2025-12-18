import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(flex: 2), // Top spacing

            // App Name & Tagline
            Column(
              children: [
                Text(
                  "MediTrack",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Stay on Track with Your Health",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Heartbeat Icon from assets
            Image.asset(
              'assets/images/heart_pulse.png',
              height: 120,
              width: 120,
            ),

            const Spacer(flex: 3), // Flexible space before buttons

            // Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text("Login"),
            ),
            const SizedBox(height: 16),

            // Sign Up Button
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.lightBlue),
              ),
              child: const Text("Sign Up"),
            ),

            const Spacer(flex: 1), // Bottom spacing
          ],
        ),
      ),
    );
  }
}

