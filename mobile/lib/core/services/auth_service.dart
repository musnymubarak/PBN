import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/models/user.dart';

/// Service handling all authentication API calls.
class AuthService {
  final _api = ApiClient();

  /// Login with email/phone and password.
  Future<void> login(String identifier, String password) async {
    final res = await _api.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    final data = _api.unwrap(res);
    await SecureStorage.setAccessToken(data['access_token']);
    await SecureStorage.setRefreshToken(data['refresh_token']);
  }

  /// Get current user profile.
  Future<User> getProfile() async {
    final res = await _api.get('/auth/me');
    return User.fromJson(_api.unwrap(res));
  }

  /// Logout — revoke refresh token & clear local storage.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Even if API fails, clear local tokens
    }
    await SecureStorage.clearAll();
  }

  /// Update FCM device token on the backend.
  Future<void> updateFcmToken(String fcmToken) async {
    await _api.post('/notifications/token', data: {
      'fcm_token': fcmToken,
    });
  }
}
