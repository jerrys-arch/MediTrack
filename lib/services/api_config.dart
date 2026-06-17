class ApiConfig {
  static const String _live = "https://meditrack-7.onrender.com/api";

  static String get baseUrl => _live;

  static String get login => "$baseUrl/auth/login/";
  static String get register => "$baseUrl/auth/register/";
  static String get tokenRefresh => "$baseUrl/auth/token/refresh/";
  static String get medications => "$baseUrl/medications/";
  static String get symptoms => "$baseUrl/symptoms/";
  static String get journals => "$baseUrl/journal/journals/";
  static String get emergencyContacts => "$baseUrl/emergency/contacts/";
  static String get care => "$baseUrl/care/";
}