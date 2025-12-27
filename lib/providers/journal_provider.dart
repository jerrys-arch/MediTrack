import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'package:provider/provider.dart';

class JournalProvider with ChangeNotifier {
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> get journals => _journals;

  final String baseUrl = 'http://127.0.0.1:8000/api/journal/journals/';

  Future<void> fetchJournals(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _journals = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      notifyListeners();
    } else {
      debugPrint('Failed to fetch journals: ${response.statusCode}');
    }
  }
}
