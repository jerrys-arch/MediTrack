import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String selectedLanguage = "English";
  String selectedTheme = "Light";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Profile"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Profile Section
            Center(
              child: Column(
                children: [
                  // Avatar
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 45),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  const Text(
                    "John Doe",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Email
                  Text(
                    "john@email.com",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),

                  // Edit Button
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Preferences Title
            const Text(
              "Preferences",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Notification Toggle
            SwitchListTile(
              title: const Text("Enable Notifications"),
              subtitle: const Text("Receive reminders and alerts"),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
              activeThumbColor: Colors.blue,
            ),

            const SizedBox(height: 15),

            // Language Selection
            const Text(
              "Language",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField(
              initialValue: selectedLanguage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Amharic", child: Text("Amharic")),
                DropdownMenuItem(value: "Oromo", child: Text("Oromo")),
              ],
              onChanged: (value) {
                setState(() => selectedLanguage = value.toString());
              },
            ),

            const SizedBox(height: 25),

            // Theme Section
            const Text(
              "Theme Mode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField(
              initialValue: selectedTheme,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Light", child: Text("Light")),
                DropdownMenuItem(value: "Dark", child: Text("Dark")),
              ],
              onChanged: (value) {
                setState(() => selectedTheme = value.toString());
              },
            ),

            const SizedBox(height: 35),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
