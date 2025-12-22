import 'package:flutter/material.dart';
import 'add_health_entry_screen.dart';

class HealthJournalScreen extends StatefulWidget {
  const HealthJournalScreen({super.key});

  @override
  State<HealthJournalScreen> createState() => _HealthJournalScreenState();
}

class _HealthJournalScreenState extends State<HealthJournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data
  List<Map<String, String>> visits = [
    {
      "date": "Oct 21, 2025",
      "title": "Doctor Visit",
      "summary": "Discussed dosage adjustment."
    },
    {
      "date": "Nov 5, 2025",
      "title": "Checkup",
      "summary": "Routine blood test done."
    },
  ];

  List<Map<String, String>> prescriptions = [
    {
      "date": "Oct 22, 2025",
      "title": "Amoxicillin 500mg",
      "summary": "Take twice daily for 7 days."
    },
    {
      "date": "Nov 6, 2025",
      "title": "Vitamin D",
      "summary": "Once daily supplement."
    },
  ];

  List<Map<String, String>> notes = [
    {
      "date": "Oct 23, 2025",
      "title": "Headache Observation",
      "summary": "Noted mild headache after afternoon."
    },
    {
      "date": "Nov 7, 2025",
      "title": "Mood Notes",
      "summary": "Feeling energetic and motivated."
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Widget _buildCard(Map<String, String> entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry["title"] ?? "",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(entry["date"] ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(entry["summary"] ?? ""),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Health Journal",
           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
   bottom: PreferredSize(
  preferredSize: const Size.fromHeight(50),
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: TabBar(
      controller: _tabController,
      labelColor: Colors.blue,          // Selected tab text color
      unselectedLabelColor: Colors.grey, // Unselected text color
      indicatorColor: Colors.blue,      // Underline indicator
      labelStyle: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14),
      tabs: const [
        Tab(text: "Visits"),
        Tab(text: "Prescriptions"),
        Tab(text: "Notes"),
      ],
      isScrollable: false,  // <-- CENTER tabs
    ),
  ),
),



      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) => _buildCard(visits[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: prescriptions.length,
              itemBuilder: (context, index) => _buildCard(prescriptions[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) => _buildCard(notes[index]),
            ),
          ),
        ],
      ),
       floatingActionButton: SizedBox(
        height: 48,
        width: 48,
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, size: 22, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddHealthEntryScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
