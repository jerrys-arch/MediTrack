
class ApiConfig {
  // Live backend URL
  static const String _live = "https://meditrack-7.onrender.com/api";

  static String get baseUrl {
    // You can still differentiate between Web and Android if needed
    // But for deployment, we use live URL everywhere
    return _live;
  }

  static String get login => "$baseUrl/auth/login/";
  static String get register => "$baseUrl/auth/register/";
  static String get medications => "$baseUrl/medications/";
  static String get symptoms => "$baseUrl/symptoms/";
  static String get journals => "$baseUrl/journal/journals/";
  static String get emergencyContacts => "$baseUrl/emergency/contacts/";
}
