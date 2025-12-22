import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, String>> contacts = [
    {
      "name": "Mom",
      "relationship": "Mother",
      "phone": "0912345678",
      "primary": "true"
    },
    {
      "name": "John",
      "relationship": "Friend",
      "phone": "0987654321",
      "primary": "false"
    }
  ];

  void _openAddContactForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController relationshipController =
            TextEditingController();
        final TextEditingController phoneController = TextEditingController();
        bool isPrimary = false;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Emergency Contact",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: "Relationship"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Checkbox(
                    value: isPrimary,
                    onChanged: (value) {
                      setState(() {
                        isPrimary = value ?? false;
                      });
                    },
                  ),
                  const Text("Set as Primary Contact")
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      // If new primary selected remove previous primary
                      if (isPrimary) {
                        for (var c in contacts) {
                          c["primary"] = "false";
                        }
                      }

                      contacts.add({
                        "name": nameController.text,
                        "relationship": relationshipController.text,
                        "phone": phoneController.text,
                        "primary": isPrimary.toString(),
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save Contact",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryContact =
        contacts.firstWhere((c) => c["primary"] == "true", orElse: () => {});

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

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          /// -----------------------------------------
          /// 1. Big Red SOS Button
          /// -----------------------------------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "CALL EMERGENCY SERVICES",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// -----------------------------------------
          /// 2. Primary Contact (if exists)
          /// -----------------------------------------
          if (primaryContact.isNotEmpty) ...[
            const Text(
              "Primary Contact",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.red, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryContact["name"]!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(primaryContact["relationship"]!),
                        Text(primaryContact["phone"]!),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.red),
                    onPressed: () {},
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],

          /// -----------------------------------------
          /// 3. Saved Contacts List
          /// -----------------------------------------
          const Text(
            "Other Contacts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...contacts
              .where((c) => c["primary"] == "false")
              .map((contact) => Card(
                    child: ListTile(
                      title: Text(contact["name"]!,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500)),
                      subtitle: Text(
                          "${contact["relationship"]!}\n${contact["phone"]!}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () {}),
                          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {}),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  contacts.remove(contact);
                                });
                              }),
                        ],
                      ),
                    ),
                  ))
        ],
      ),
    );
  }
}
