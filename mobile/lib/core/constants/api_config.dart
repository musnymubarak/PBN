/// API configuration constants.
class ApiConfig {
  /// Change this to your backend URL.
  /// Windows desktop / web:  http://localhost:8000/api/v1
  /// Android emulator:       http://10.0.2.2:8000/api/v1
  /// Physical device:        http://<YOUR_LAN_IP>:8000/api/v1
  /// VPS Production:       http://37.59.123.98:8005/api/v1
  //static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static const String baseUrl = 'http://37.59.123.98:8005/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}