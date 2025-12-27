import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'package:provider/provider.dart';

class SymptomProvider with ChangeNotifier {
  List<Map<String, dynamic>> _symptoms = [];
  List<Map<String, dynamic>> get symptoms => _symptoms;

  final String baseUrl = 'http://127.0.0.1:8000/api/symptoms/';

  Future<void> fetchSymptoms(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _symptoms = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      notifyListeners();
    } else {
      debugPrint('Failed to fetch symptoms: ${response.statusCode}');
    }
  }
}
