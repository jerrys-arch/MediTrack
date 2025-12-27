import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import 'add_symptom_entry_screen.dart';
import 'package:http/http.dart' as http;

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  List<Map<String, dynamic>> recentLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
  }

  Future<void> _fetchSymptoms() async {
    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await http.get(
        Uri.parse(ApiConfig.symptoms),
        headers: {
          'Authorization': 'Bearer ${authProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          recentLogs = data.map<Map<String, dynamic>>((item) {
            return {
              "date": item['date'] ?? "",
              "mood": item['mood'] ?? "",
              "note": item['note'] ?? "",
              "pain": item['pain_level'] ?? "",
              "tags": item['tag'] != null
                  ? <String>[item['tag'].toString()]
                  : <String>[],
            };
          }).toList();
        });
      } else {
        _showError("Failed to load symptoms");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final List<String> tags = List<String>.from(log["tags"] ?? []);

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
            // Date & Mood
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

            // Tags
            Wrap(
              spacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Pain Level
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
      floatingActionButton: SizedBox(
        height: 48,
        width: 48,
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, size: 22, color: Colors.white),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddSymptomEntryScreen(),
              ),
            );
            if (added == true) {
              _fetchSymptoms();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : recentLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart,
                            size: 64, color: Colors.blue.shade300),
                        const SizedBox(height: 20),
                        const Text(
                          "No symptoms logged yet!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Track your symptoms daily to stay on top of your health.\nTap the + button below to log your first symptom.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Logs",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: recentLogs.length,
                          itemBuilder: (context, index) {
                            return _buildLogCard(recentLogs[index]);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
