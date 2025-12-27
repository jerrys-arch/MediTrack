import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import 'add_medication_screen.dart';
import 'package:http/http.dart' as http;

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<Map<String, dynamic>> medications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    setState(() {
      isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.medications), // ✅ NO userId needed
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            medications = List<Map<String, dynamic>>.from(decoded);
          });
        } else {
          setState(() {
            medications = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching medications: $e');
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void openAddMedicationScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _fetchMedications();
    }
  }

  Widget _medicationCard(Map<String, dynamic> med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.medication_liquid,
              size: 32,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    med["dosage"] ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Frequency tag styled like a button
                if (med["frequency"] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      med["frequency"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Time
                Text(
                  med["time"]?.toString() ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Reminder icon
                Icon(
                  med["reminder"] == true
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: Colors.blue,
                  size: 26,
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
        title: const Text(
          "Medication Schedule",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4),
        child: SizedBox(
          width: 52,
          height: 52,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: openAddMedicationScreen,
            child: const Icon(Icons.add, size: 26, color: Colors.white),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medications.isEmpty
              ? const Center(child: Text("No medications added yet."))
              : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return _medicationCard(med);
                    },
                  ),
                ),
    );
  }
}
