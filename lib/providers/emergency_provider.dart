import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../services/api_config.dart'; // Add this

class EmergencyProvider with ChangeNotifier {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> get contacts => _contacts;

  Future<void> fetchContacts(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.emergencyContacts), // ✅ Use ApiConfig
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // ✅ Web-safe JSON parsing
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> dataList = decoded is List 
            ? decoded 
            : (decoded as Map?)?['results'] ?? [];
        
        _contacts = dataList.map<Map<String, dynamic>>((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return {
            'id': map['id'],
            'name': map['name']?.toString() ?? '',
            'phone_number': map['phone_number']?.toString() ?? '',
            'relationship': map['relationship']?.toString() ?? '',
            'is_primary': map['is_primary'] ?? false,
            'date_added': map['date_added']?.toString() ?? '',
          };
        }).toList();
        
        notifyListeners();
      } else {
        debugPrint('Failed to fetch contacts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    }
  }

  // Bonus: Add method to refresh contacts
  void refreshContacts(BuildContext context) {
    fetchContacts(context);
  }
}
