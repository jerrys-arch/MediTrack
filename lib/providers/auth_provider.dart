import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_config.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _userName;
  String? _userRole;
  bool _notificationsEnabled = true;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  bool get isCaregiver => _userRole == 'caregiver';
  bool get isPatient => _userRole == 'patient';
  bool get notificationsEnabled => _notificationsEnabled;

  // ── Load tokens on app start ──────────────────────────────────────────────

  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
    _userId = await _storage.read(key: 'userId');
    _userName = await _storage.read(key: 'userName');
    _userRole = await _storage.read(key: 'userRole');
    final notif = await _storage.read(key: 'notificationsEnabled');
    _notificationsEnabled = notif == null ? true : notif == 'true';
    notifyListeners();
  }

  // ── Refresh access token ──────────────────────────────────────────────────
  // Called on app start if we have a refresh token.
  // Returns true if successful, false if refresh token is also expired.

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.tokenRefresh),   // /api/auth/token/refresh/
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        await _storage.write(key: 'accessToken', value: _accessToken);
        notifyListeners();
        return true;
      }

      // Refresh token expired — clear everything and send to login
      await logout();
      return false;
    } catch (_) {
      // Network error — keep existing tokens, user may be offline
      // Don't log out just because of a network failure
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<String?> register(
    String email,
    String fullName,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 201) return null;

      final body = jsonDecode(response.body);
      return _parseApiErrors(body);
    } catch (_) {
      return 'Could not connect to the server. Check your internet connection.';
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _accessToken = data['access'];
        _refreshToken = data['refresh'];
        _userId = data['user']['id'].toString();
        _userName = data['user']['name'] ?? 'User';
        _userRole = data['user']['role'] ?? 'patient';

        await _storage.write(key: 'accessToken', value: _accessToken);
        await _storage.write(key: 'refreshToken', value: _refreshToken);
        await _storage.write(key: 'userId', value: _userId);
        await _storage.write(key: 'userName', value: _userName);
        await _storage.write(key: 'userRole', value: _userRole);

        notifyListeners();
        return null; // success
      }

      if (response.statusCode == 401) {
        return 'Incorrect email or password.';
      }

      // Server error
      return 'Server error (${response.statusCode}). Please try again.';
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'Server is taking too long to respond.\n'
            'The server may be waking up — please wait 30 seconds and try again.';
      }
      return 'Could not connect. Check your internet connection.';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _userRole = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(key: 'notificationsEnabled', value: value.toString());
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _parseApiErrors(dynamic body) {
    if (body is Map) {
      final messages = <String>[];
      body.forEach((field, errors) {
        final fieldName = _friendlyFieldName(field.toString());
        if (errors is List) {
          for (final e in errors) { messages.add('$fieldName: $e'); }
        } else {
          messages.add('$fieldName: $errors');
        }
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }
    if (body is String) return body;
    return 'Registration failed. Please try again.';
  }

  String _friendlyFieldName(String field) {
    switch (field) {
      case 'email': return 'Email';
      case 'password': return 'Password';
      case 'full_name': return 'Full name';
      case 'role': return 'Role';
      case 'non_field_errors': return 'Error';
      default: return field[0].toUpperCase() + field.substring(1);
    }
  }
}