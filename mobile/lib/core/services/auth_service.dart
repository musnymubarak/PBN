import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/models/user.dart';

/// Service handling all authentication API calls.
class AuthService {
  final _api = ApiClient();

  /// Step 1: Request OTP for phone number.
  Future<void> sendOtp(String phoneNumber) async {
    await _api.post('/auth/send-otp', data: {
      'phone_number': phoneNumber,
    });
  }

  /// Step 2: Verify OTP → receive and store tokens.
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    final res = await _api.post('/auth/verify-otp', data: {
      'phone_number': phoneNumber,
      'otp': otp,
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
