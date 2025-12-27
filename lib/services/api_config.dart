import 'package:flutter/foundation.dart';

class ApiConfig {
  // Android emulator → maps to host machine localhost
  static const String _androidEmulator = "http://10.0.2.2:8000/api";

  // Default local backend (for Web/Desktop)
  static const String _localhost = "http://localhost:8000/api";

  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulator; // Android emulator
    }

    // Web / Desktop → use localhost
    return _localhost;
  }

  static String get login => "$baseUrl/auth/login/";
  static String get register => "$baseUrl/auth/register/";
  static String get medications => "$baseUrl/medications/";
  static String get symptoms => "$baseUrl/symptoms/";
  static String get journals => "$baseUrl/journal/journals/";
  static String get emergencyContacts => "$baseUrl/emergency/contacts/";
}
