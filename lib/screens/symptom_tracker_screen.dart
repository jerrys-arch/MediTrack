import 'package:flutter/material.dart';
//import 'add_symptom_entry_screen.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  List<Map<String, dynamic>> recentLogs = [
    {
      "date": "Dec 2, 2025",
      "mood": "😊",
      "note": "Felt energetic today, slight headache.",
      "tag": "Headache",
      "pain": "Low"
    },
    {
      "date": "Dec 1, 2025",
      "mood": "😐",
      "note": "Normal day, mild fatigue.",
      "tag": "Fatigue",
      "pain": "Medium"
    },
    {
      "date": "Nov 30, 2025",
      "mood": "😞",
      "note": "Bad stomach pain after lunch.",
      "tag": "Stomach Pain",
      "pain": "High"
    }
  ];

  // Method to build the log card
  Widget _buildLogCard(Map<String, dynamic> log) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log["date"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                log["mood"],
                style: const TextStyle(fontSize: 34),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log["note"],
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),

          // 🔵 Tag styled consistently with other cards
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.blue, // same blue as other widgets
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              log["tag"],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.local_hospital,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                "Pain Level: ${log["pain"]}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Symptom Tracker",
           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      /*floatingActionButton: SizedBox(
        height: 48,
        width: 48,
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, size: 22, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddSymptomEntryScreen(),
              ),
            );
          },
        ),
      ),*/

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Logs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: recentLogs.length,
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  return _buildLogCard(log); // Uses the method to build the card
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}