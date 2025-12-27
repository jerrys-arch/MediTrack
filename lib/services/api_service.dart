import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await storage.write(key: 'access', value: data['access']);
      await storage.write(key: 'refresh', value: data['refresh']);
      return data;
    }
    throw Exception("Login failed");
  }

  Future<http.Response> get(String endpoint) async {
    final token = await storage.read(key: 'access');
    return http.get(
      Uri.parse("${ApiConfig.baseUrl}/$endpoint"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
