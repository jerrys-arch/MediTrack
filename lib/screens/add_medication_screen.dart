import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = "";
  String dosage = "";
  String time = "";
  String notes = "";
  String frequency = "Daily";
  bool reminderEnabled = true;
  bool isSaving = false;

  Future<void> _saveMedication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) return;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.medications),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
         
          'name': name,
          'dosage': dosage,
          'time': time,
          'frequency': frequency,
          'notes': notes,
          'reminder': reminderEnabled, // ✅ FIXED
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add medication.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Medication",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Medication Name",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => name = val ?? "",
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please enter medication name' : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  "Dosage (e.g. 100mg)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => dosage = val ?? "",
                ),
                const SizedBox(height: 16),

                const Text(
                  "Time (e.g. 8:00 AM)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => time = val ?? "",
                ),
                const SizedBox(height: 16),

                const Text(
                  "Frequency",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  initialValue: frequency,
                  items: ["Daily", "Weekly", "Custom"]
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => frequency = val!);
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  "Notes",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => notes = val ?? "",
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Enable Reminder", style: TextStyle(fontSize: 16)),
                  value: reminderEnabled,
                  onChanged: (bool newValue) {
                    setState(() => reminderEnabled = newValue);
                  },
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveMedication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Medication",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}