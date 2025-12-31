import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_config.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  // User info
  String? _userId;
  String? _userName;

  // 🔹 Global notification toggle
  bool _notificationsEnabled = true;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  String? get userId => _userId;
  String? get userName => _userName;

  bool get notificationsEnabled => _notificationsEnabled;

  // ------------------------
  // Load tokens and notification preference
  // ------------------------
  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
    _userId = await _storage.read(key: 'userId');
    _userName = await _storage.read(key: 'userName');
    final notif = await _storage.read(key: 'notificationsEnabled');
    _notificationsEnabled = notif == null ? true : notif == 'true';
    notifyListeners();
  }

  // ------------------------
  // Register
  // ------------------------
  Future<bool> register(String email, String fullName, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'password': password,
      }),
    );

    return response.statusCode == 201;
  }

  // ------------------------
  // Login
  // ------------------------
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      _accessToken = data['access'];
      _refreshToken = data['refresh'];

      _userId = data['user']['id'].toString();
      _userName = data['user']['name'] ?? 'User';

      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
      await _storage.write(key: 'userId', value: _userId);
      await _storage.write(key: 'userName', value: _userName);

      notifyListeners();
      return true;
    }

    return false;
  }

  // ------------------------
  // Logout
  // ------------------------
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  // ------------------------
  // 🔹 Notification toggle methods
  // ------------------------
  void setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(key: 'notificationsEnabled', value: value.toString());
    notifyListeners();
  }
}
