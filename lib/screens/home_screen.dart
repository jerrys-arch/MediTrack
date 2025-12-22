import 'package:flutter/material.dart';
import 'medication_screen.dart';
import 'add_medication_screen.dart';
import 'symptom_tracker_screen.dart';
import 'add_symptom_entry_screen.dart';
import 'health_journal_screen.dart';
import 'add_health_entry_screen.dart';
import 'emergency_screen.dart';
import 'settings_screen.dart'; 

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final String userName = "John"; 

  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MedicationScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SymptomTrackerScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HealthJournalScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalHorizontalPadding = 16.0 * 2;
    final double spacingBetweenButtons = 16.0;
    final double btnWidth =
        (MediaQuery.of(context).size.width - totalHorizontalPadding - spacingBetweenButtons) / 2;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Text(
              "Good Morning, $userName",
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            /// ✅ PROFILE AVATAR NOW TAPPABLE
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today’s Medications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _medicationCard("Amoxicillin 500mg", "8:00 AM"),
            _medicationCard("Vitamin D", "2:00 PM"),
            _medicationCard("Ibuprofen 200mg", "6:00 PM"),

            const SizedBox(height: 25),

            const Text(
              "Upcoming Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _reminderCard("Paracetamol", "Tomorrow - 8:00 AM"),
                  _reminderCard("Calcium Tablet", "Tomorrow - 12:00 PM"),
                  _reminderCard("Eye Drops", "Tomorrow - 6:00 PM"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(width: btnWidth, child: _quickActionButton(Icons.add_circle, "Add Medication")),
                SizedBox(width: btnWidth, child: _quickActionButton(Icons.fact_check, "Log Symptom")),
                SizedBox(width: btnWidth, child: _quickActionButton(Icons.book, "Add Entry")),
                SizedBox(width: btnWidth, child: _quickActionButton(Icons.call, "Emergency")),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: "Medications"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Tracker"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Journal"),
        ],
      ),
    );
  }

  Widget _medicationCard(String name, String time) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.medication_liquid,
            size: 32,
            color: Colors.blue, // Icon color
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              backgroundColor: Colors.blue, // Same blue as icon
              foregroundColor: Colors.white,
            ),
            child: const Text("Mark as Taken"),
          ),
        ],
      ),
    ),
  );
}

  Widget _reminderCard(String title, String time) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active, size: 28, color: Colors.blue),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (label == "Add Medication") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
            } else if (label == "Log Symptom") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSymptomEntryScreen()));
            } else if (label == "Add Entry") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddHealthEntryScreen()));
            } else if (label == "Emergency") {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
