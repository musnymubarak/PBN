/// API configuration constants.
class ApiConfig {
  /// Change this to your backend URL.
  /// Android emulator: http://10.0.2.2:8000/api/v1
  /// Physical device:  http://<YOUR_LAN_IP>:8000/api/v1
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
