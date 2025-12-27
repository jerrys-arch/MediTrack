import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import 'medication_screen.dart';
import 'add_medication_screen.dart';
import 'symptom_tracker_screen.dart';
import 'add_symptom_entry_screen.dart';
import 'health_journal_screen.dart';
import 'add_health_entry_screen.dart';
import 'emergency_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> allMedications = [];
  List<Map<String, dynamic>> todaysMedications = [];
  List<Map<String, dynamic>> upcomingReminders = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicationScreen()));
    } else if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SymptomTrackerScreen()));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HealthJournalScreen()));
    }
  }

  Future<void> _fetchMedications() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.medications),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        allMedications = List<Map<String, dynamic>>.from(data);

        final now = DateTime.now();

        todaysMedications = allMedications.where((med) {
          final createdAt = DateTime.tryParse(med['created_at'] ?? '');
          if (createdAt == null) return false;
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        }).toList();

        upcomingReminders =
            allMedications.where((med) => med['reminder'] == true).toList();
      }
    } catch (e) {
      debugPrint('Error fetching medications: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markMedicationAsTaken(int medId) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.medications}$medId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'taken': true}),
      );

      if (response.statusCode == 200) {
        await _fetchMedications();
      }
    } catch (e) {
      debugPrint('Error marking medication as taken: $e');
    }
  }

  Future<void> _handleQuickAction(String label) async {
    if (label == "Add Medication") {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
      );
      if (result == true) _fetchMedications();
    } else if (label == "Log Symptom") {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddSymptomEntryScreen()));
    } else if (label == "Add Entry") {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddHealthEntryScreen()));
    } else if (label == "Emergency") {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        Provider.of<AuthProvider>(context).userName ?? "User";

    final btnWidth = (MediaQuery.of(context).size.width - 48) / 2;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Good Morning, $userName",
          style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.blue),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today’s Medications",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  todaysMedications.isEmpty
                      ? _infoCard(
                          icon: Icons.medication,
                          title: "No medications today",
                          subtitle:
                              "Your medications will appear here once added.",
                        )
                      : Column(
                          children: todaysMedications
                              .map((med) => _medicationCard(
                                    med['id'],
                                    med['name'],
                                    med['time'],
                                    med['taken'] ?? false,
                                  ))
                              .toList(),
                        ),

                  const SizedBox(height: 24),
                  const Text("Upcoming Reminders",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  upcomingReminders.isEmpty
                      ? _infoCard(
                          icon: Icons.notifications_off,
                          title: "No reminders yet",
                          subtitle:
                              "Reminders will show here when enabled.",
                        )
                      : SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: upcomingReminders
                                .map((med) =>
                                    _reminderCard(med['name'], med['time']))
                                .toList(),
                          ),
                        ),

                  const SizedBox(height: 24),
                  const Text("Quick Actions",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                          width: btnWidth,
                          child: _quickActionButton(
                              Icons.add_circle, "Add Medication")),
                      SizedBox(
                          width: btnWidth,
                          child: _quickActionButton(
                              Icons.fact_check, "Log Symptom")),
                      SizedBox(
                          width: btnWidth,
                          child:
                              _quickActionButton(Icons.book, "Add Entry")),
                      SizedBox(
                          width: btnWidth,
                          child: _quickActionButton(
                              Icons.call, "Emergency")),
                    ],
                  ),
                ],
              ),
            ),
   
  bottomNavigationBar
  : BottomNavigationBar
  ( selectedItemColor: Colors.blue, unselectedItemColor: Colors.grey, 
  currentIndex: _currentIndex, 
  onTap: _onNavTap, 
  showSelectedLabels: true, 
  showUnselectedLabels: true, 
  items: const [ BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), 
  BottomNavigationBarItem(icon: Icon(Icons.medication), label: "Medications"), 
  BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Tracker"), 
  BottomNavigationBarItem(icon: Icon(Icons.book), label: "Journal"), ], ), ); }

  // ---------- Shared UI ----------

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _medicationCard(int id, String name, String time, bool taken) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(name),
        subtitle: Text(time),
        trailing: ElevatedButton(
          onPressed: taken ? null : () => _markMedicationAsTaken(id),
          child: Text(taken ? "Taken" : "Mark as Taken"),
        ),
      ),
    );
  }

  Widget _reminderCard(String name, String time) {
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active, color: Colors.blue),
          const SizedBox(height: 8),
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label) {
  return InkWell(
    onTap: () => _handleQuickAction(label),
    splashColor: Colors.transparent,   // removes ripple effect
    highlightColor: Colors.transparent, // removes highlight on press
    child: Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

}
