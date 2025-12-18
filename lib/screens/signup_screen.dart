import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Back Arrow
               // 🔹 Back Arrow (Updated to match HomeDashboardScreen)
Align(
  alignment: Alignment.topLeft,
  child: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black87),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
),


                const SizedBox(height: 40),

                // 🔹 Header
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "Create Your MediTrack Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Start your journey to better health management today",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 🔹 Full Name
                TextField(
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30), // Makes it round
    ),
                    suffixIcon: const Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Email
                TextField(
                  decoration: InputDecoration(
                    labelText: "Email",
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30), // Makes it round
    ),
                    suffixIcon: const Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Password
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30), // Makes it round
    ),
                    suffixIcon: const Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Confirm Password
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30), // Makes it round
    ),
                    suffixIcon: const Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Create Account Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Login Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
