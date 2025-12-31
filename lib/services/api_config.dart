import 'package:flutter/foundation.dart';

class ApiConfig {
  // Your PC's local IP (real phone access)
  static const String _androidPhysical =
      "http://192.168.1.102:8000/api";

  // Android Emulator
 // static const String _androidEmulator =
   //   "http://10.0.2.2:8000/api";

  // Web / Desktop
  static const String _localhost =
      "http://localhost:8000/api";

  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidPhysical; // REAL PHONE
    }
    return _localhost;
  }

  static String get login => "$baseUrl/auth/login/";
  static String get register => "$baseUrl/auth/register/";
  static String get medications => "$baseUrl/medications/";
  static String get symptoms => "$baseUrl/symptoms/";
  static String get journals => "$baseUrl/journal/journals/";
  static String get emergencyContacts => "$baseUrl/emergency/contacts/";
}
