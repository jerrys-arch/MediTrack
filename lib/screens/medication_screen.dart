import 'package:flutter/material.dart';
//import 'add_medication_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Mock FRONTEND data
  final List<Map<String, dynamic>> medications = [
    {
      "name": "Aspirin",
      "dosage": "100mg",
      "frequency": "Daily",
      "time": "8:00 AM",
      "reminder": true
    },
    {
      "name": "Vitamin D",
      "dosage": "1 Capsule",
      "frequency": "Weekly",
      "time": "7:00 AM",
      "reminder": false
    },
    {
      "name": "Ibuprofen",
      "dosage": "200mg",
      "frequency": "Daily",
      "time": "1:00 PM",
      "reminder": true
    },
    {
      "name": "Cough Syrup",
      "dosage": "10ml",
      "frequency": "Custom",
      "time": "9:00 PM",
      "reminder": false
    },
  ];

  /*void openAddMedicationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    );
  }*/

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

      /*floatingActionButton: Padding(
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
      ),*/

      body: Padding(
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

  // ✅ Same card STYLE as previous widget, same CONTENT as your original
  Widget _medicationCard(Map<String, dynamic> med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // same radius
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // same padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.medication_liquid,
              size: 32,
              color: Colors.blue, // same icon color
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med["name"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    med["dosage"],
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
                // 🔵 Frequency tag styled like a button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue, // same as button bg
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    med["frequency"],
                    style: const TextStyle(
                      color: Colors.white, // button-like text
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  med["time"],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  med["reminder"]
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
}
