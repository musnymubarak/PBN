import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/models/user.dart';

/// Service handling all authentication API calls.
class AuthService {
  final _api = ApiClient();

  /// Login with email/phone and password.
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await _api.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      final data = _api.unwrap(res);
      if (data['requires_2fa'] != true) {
        await SecureStorage.setAccessToken(data['access_token']);
        await SecureStorage.setRefreshToken(data['refresh_token']);
      }
      return data;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message'].toString());
      }
      throw Exception('Login failed. Please check your credentials.');
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  /// Verify 2FA OTP code.
  Future<void> verify2FA(String tfaToken, String otp) async {
    try {
      final res = await _api.post('/auth/verify-2fa', data: {
        'tfa_token': tfaToken,
        'otp': otp,
      });
      final data = _api.unwrap(res);
      await SecureStorage.setAccessToken(data['access_token']);
      await SecureStorage.setRefreshToken(data['refresh_token']);
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message'].toString());
      }
      throw Exception('Verification failed. Please try again.');
    } catch (e) {
      throw Exception('An unexpected error occurred during verification.');
    }
  }

  /// Resend 2FA OTP code.
  Future<void> resend2FA(String tfaToken) async {
    try {
      await _api.post('/auth/resend-2fa', data: {
        'tfa_token': tfaToken,
      });
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message'].toString());
      }
      throw Exception('Failed to resend code. Please try again.');
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  /// Toggle 2FA setting.
  Future<bool> toggle2FA(bool enable, String password) async {
    try {
      final res = await _api.put('/auth/2fa', data: {
        'enable': enable,
        'password': password,
      });
      final data = _api.unwrap(res);
      return data['two_factor_enabled'] ?? false;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response?.data['message'].toString());
      }
      throw Exception('Failed to toggle Two-Factor Authentication.');
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
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

  /// Change current user password.
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await _api.put('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': newPassword,
      });
      return true;
    } on DioException catch (e) {
      debugPrint('Change password failed: ${e.response?.data}');
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
          throw Exception(e.response?.data['detail'].toString());
      }
      if (e.response?.data is Map && e.response?.data['message'] != null) {
          throw Exception(e.response?.data['message'].toString());
      }
      throw Exception(e.message ?? 'Unknown error occurred');
    } catch (e) {
      debugPrint('Change password failed: $e');
      throw Exception(e.toString());
    }
  }
}
