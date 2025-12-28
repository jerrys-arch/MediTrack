import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<dynamic> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.emergencyContacts),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          contacts = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch contacts: ${response.body}');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addContact(
      String name, String relationship, String phone, bool isPrimary) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.emergencyContacts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.accessToken}',
        },
        body: jsonEncode({
          'name': name,
          'relationship': relationship,
          'phone_number': phone,
          'is_primary': isPrimary,
        }),
      );

      if (response.statusCode == 201) {
        _fetchContacts();
      } else {
        debugPrint('Failed to add contact: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  void _openAddContactForm() {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Emergency Contact",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(labelText: "Relationship"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),
            Row(
              children: [
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Checkbox(
                      value: isPrimary,
                      onChanged: (v) {
                        setInnerState(() => isPrimary = v ?? false);
                      },
                    );
                  },
                ),
                const Text("Set as Primary")
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _addContact(
                    nameController.text.trim(),
                    relationshipController.text.trim(),
                    phoneController.text.trim(),
                    isPrimary,
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Contact",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryContact =
        contacts.where((c) => c['is_primary'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _openAddContactForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: () {
                        // emergency call action
                      },
                      child: const Text(
                        "CALL EMERGENCY SERVICES",
                        style:
                            TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (primaryContact.isNotEmpty) ...[
                      const Text(
                        "Primary Contact",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _contactCard(primaryContact.first, true),
                      const SizedBox(height: 30),
                    ],
                    const Text(
                      "Other Contacts",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...contacts
                        .where((c) => c['is_primary'] == false)
                        .map((c) => _contactCard(c, false)),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.contact_phone,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              "No Emergency Contacts Yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "Add trusted people who can be contacted in case of an emergency.\n\nTap the + button below to get started.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(dynamic contact, bool isPrimary) {
    return Card(
      child: ListTile(
        title: Text(contact['name']),
        subtitle: Text(
            "${contact['relationship'] ?? ''}\n${contact['phone_number']}"),
        isThreeLine: true,
        trailing:
            isPrimary ? const Icon(Icons.star, color: Colors.red) : null,
      ),
    );
  }
}
