import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class AddSymptomEntryScreen extends StatefulWidget {
  const AddSymptomEntryScreen({super.key});

  @override
  State<AddSymptomEntryScreen> createState() => _AddSymptomEntryScreenState();
}

class _AddSymptomEntryScreenState extends State<AddSymptomEntryScreen> {
  int _selectedMood = 2; // 1 = Bad, 2 = Okay, 3 = Good
  String _selectedPainLevel = "None";
  final TextEditingController _symptomController = TextEditingController();
  bool isSaving = false;

  final List<String> tags = [
    "Headache", "Fatigue", "Cough", "Nausea",
    "Fever", "Dizziness", "Pain", "Stress"
  ];
  final List<String> selectedTags = [];

  // Map frontend pain levels to backend
  String _mapPainLevel(String value) {
    switch (value) {
      case "Mild":
        return "Low";
      case "Moderate":
        return "Medium";
      case "Severe":
        return "High";
      default:
        return "Low";
    }
  }

  Future<void> _saveSymptom() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.symptoms),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.accessToken}',
        },
        body: jsonEncode({
          "mood": _selectedMood == 1
              ? "😞"
              : _selectedMood == 2
                  ? "😐"
                  : "😊",
          "note": _symptomController.text.trim(),
          "tag": selectedTags.isNotEmpty ? selectedTags.first : "General",
          "pain_level": _mapPainLevel(_selectedPainLevel),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _showError("Failed to save symptom");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: ["None", "Mild", "Moderate", "Severe"]
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPainLevel = value!),
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
                  onPressed: isSaving ? null : _saveSymptom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
