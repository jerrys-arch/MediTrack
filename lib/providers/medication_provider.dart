import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'package:provider/provider.dart';

class MedicationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> get medications => _medications;

  final String baseUrl = 'http://127.0.0.1:8000/api/medications/';

  Future<void> fetchMedications(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    final response = await http.get(
      Uri.parse(baseUrl), // ✅ NO userId
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ✅ SAFE parsing
      if (decoded is List) {
        _medications = List<Map<String, dynamic>>.from(decoded);
      } else {
        _medications = [];
      }

      notifyListeners();
    } else {
      debugPrint('Failed to fetch medications: ${response.statusCode}');
    }
  }
}
