import 'package:flutter/material.dart';

class AddSymptomEntryScreen extends StatefulWidget {
  const AddSymptomEntryScreen({super.key});

  @override
  State<AddSymptomEntryScreen> createState() => _AddSymptomEntryScreenState();
}

class _AddSymptomEntryScreenState extends State<AddSymptomEntryScreen> {
  int _selectedMood = 2; // 1 = Bad, 2 = Okay, 3 = Good
  String _selectedPainLevel = "None";

  final TextEditingController _symptomController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  /// Tags
  final List<String> tags = [
    "Headache", "Fatigue", "Cough", "Nausea",
    "Fever", "Dizziness", "Pain", "Stress"
  ];

  final List<String> selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed backgroundColor to use default scaffold background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Symptom Entry",
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

             // DATE PICKER
InkWell(
  onTap: () async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  },
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      // Remove color, just use border
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade400),
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ),
  ),
),

              const SizedBox(height: 20),

              // MOOD ICONS
              const Text(
                "How do you feel?",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodIcon(1, "😞 Bad"),
                  _buildMoodIcon(2, "😐 Okay"),
                  _buildMoodIcon(3, "😊 Good"),
                ],
              ),

              const SizedBox(height: 20),
// PAIN LEVEL DROPDOWN
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade400),
  ),
  child: DropdownButtonFormField<String>(
    initialValue: _selectedPainLevel,
    decoration: const InputDecoration(
      border: InputBorder.none,
    ),
    items: ["None", "Mild", "Moderate", "Severe"]
        .map((level) => DropdownMenuItem(
              value: level,
              child: Text(level),
            ))
        .toList(),
    onChanged: (value) {
      setState(() => _selectedPainLevel = value!);
    },
  ),
),
              const SizedBox(height: 20),

              // TAGS
              const Text(
                "Tags (select what applies)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: tags.map((tag) {
                  bool selected = selectedTags.contains(tag);

                  return ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    selectedColor: Colors.blue.shade200,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // DESCRIPTION
              const Text(
                "Describe your symptoms",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              TextField(
                controller: _symptomController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String moodEmoji = _selectedMood == 1
                        ? "😞"
                        : _selectedMood == 2
                            ? "😐"
                            : "😊";

                    Navigator.pop(context, {
                      "date":
                          "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}",
                      "mood": moodEmoji,
                      "note": _symptomController.text.trim(),
                      "pain": _selectedPainLevel,
                      "tags": selectedTags,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Entry",
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Mood Icon Widget
  Widget _buildMoodIcon(int mood, String label) {
    bool selected = _selectedMood == mood;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _selectedMood = mood),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? Colors.blue.shade100 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.blue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              label.split(" ")[0],
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label.split(" ")[1]),
      ],
    );
  }
}
