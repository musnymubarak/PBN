import 'package:flutter/material.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/notification_service.dart';
import 'package:pbn/core/services/push_notification_service.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global auth state accessible via Provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

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
        _registerFcmToken();
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

  /// Login with email/phone and password.
  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(identifier, password);
      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      _registerFcmToken();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Invalid credentials. Please check your email/phone and password.';
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

  /// Get FCM token and send to backend
  Future<void> _registerFcmToken() async {
    try {
      final token = await PushNotificationService.getToken();
      if (token != null) {
        await _notificationService.registerFcmToken(token);
        debugPrint("FCM token registered: $token");
      }
    } catch (e) {
      debugPrint("Failed to register FCM token: $e");
    }
  }
}
