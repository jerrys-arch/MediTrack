import 'package:flutter/material.dart';

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
                // Medication Name
                const Text(
                  "Medication Name",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => name = val ?? "",
                ),
                const SizedBox(height: 16),

                // Dosage
                const Text(
                  "Dosage (e.g. 100mg)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => dosage = val ?? "",
                ),
                const SizedBox(height: 16),

                // Time
                const Text(
                  "Time (e.g. 8:00 AM)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => time = val ?? "",
                ),
                const SizedBox(height: 16),

                // Frequency Dropdown
                const Text(
                  "Frequency",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  initialValue: frequency,
                  items: ["Daily", "Weekly", "Custom"]
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      frequency = val!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                const Text(
                  "Notes",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => notes = val ?? "",
                ),
                const SizedBox(height: 16),

                // Reminder Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Enable Reminder",
                    style: TextStyle(fontSize: 16),
                  ),
                  value: reminderEnabled,
                  onChanged: (bool newValue) {
                    setState(() {
                      reminderEnabled = newValue;
                    });
                  },
                ),

                const SizedBox(height: 30),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _formKey.currentState!.save();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
