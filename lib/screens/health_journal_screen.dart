import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import 'add_health_entry_screen.dart';
import 'package:http/http.dart' as http;

class HealthJournalScreen extends StatefulWidget {
  const HealthJournalScreen({super.key});

  @override
  State<HealthJournalScreen> createState() => _HealthJournalScreenState();
}

class _HealthJournalScreenState extends State<HealthJournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

  List<Map<String, String>> visits = [];
  List<Map<String, String>> prescriptions = [];
  List<Map<String, String>> notes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHealthEntries();
  }

  Future<void> _fetchHealthEntries() async {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.journals),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        visits.clear();
        prescriptions.clear();
        notes.clear();

        for (var entry in data) {
          String formattedDate = "";
          if (entry["date"] != null && entry["date"] != "") {
            final dt = DateTime.parse(entry["date"]).toLocal();
            formattedDate =
                "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }

          final map = <String, String>{
            "title": entry["title"] ?? "",
            "description": entry["description"] ?? "",
            "date": formattedDate,
          };

          final title = map["title"]!.toLowerCase();
          if (title.contains("visit")) {
            visits.add(map);
          } else if (title.contains("prescription") || title.contains("med")) {
            prescriptions.add(map);
          } else {
            notes.add(map);
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddHealthEntryScreen()),
    );

    if (result == true) {
      _fetchHealthEntries();
    }
  }

  Widget _buildCard(Map<String, String> entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry["title"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(entry["date"] ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(entry["description"] ?? ""),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.blue.shade300),
          const SizedBox(height: 20),
          const Text(
            "No entries yet!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
  backgroundColor: Colors.white,
  title: const Text(
    "Health Journal",
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
  ),
  bottom: TabBar(
    controller: _tabController,
    indicatorColor: Colors.blue,
    labelColor: Colors.blue,
    unselectedLabelColor: Colors.black87,
    mouseCursor: SystemMouseCursors.click, 
    tabs: const [
      Tab(text: "Visits"),
      Tab(text: "Prescriptions"),
      Tab(text: "Notes"),
    ],
  ),
),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                visits.isEmpty
                    ? _emptyState(
                        "Log your doctor visits to keep track of your health history.\nTap the + button below to add your first visit.")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visits.length,
                        itemBuilder: (_, i) => _buildCard(visits[i]),
                      ),
                prescriptions.isEmpty
                    ? _emptyState(
                        "Add your prescriptions to track medications and dosages.\nTap the + button below to add your first prescription.")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: prescriptions.length,
                        itemBuilder: (_, i) => _buildCard(prescriptions[i]),
                      ),
                notes.isEmpty
                    ? _emptyState(
                        "Keep notes on your health observations, symptoms, or reminders.\nTap the + button below to add your first note.")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notes.length,
                        itemBuilder: (_, i) => _buildCard(notes[i]),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
