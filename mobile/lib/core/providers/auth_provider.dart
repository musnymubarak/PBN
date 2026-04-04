import 'package:flutter/material.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global auth state accessible via Provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Check if user has valid tokens on app start.
  Future<void> tryAutoLogin() async {
    _loading = true;
    notifyListeners();

    try {
      final hasTokens = await SecureStorage.hasTokens();
      if (hasTokens) {
        _user = await _authService.getProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      await SecureStorage.clearAll();
    }

    _loading = false;
    notifyListeners();
  }

  /// Send OTP to phone number.
  Future<bool> sendOtp(String phoneNumber) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOtp(phoneNumber);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send OTP. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and login.
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyOtp(phoneNumber, otp);
      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Invalid OTP. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout and clear state.
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }
}
