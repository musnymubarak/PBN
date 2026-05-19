import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/auth_service.dart';
import 'package:pbn/core/services/notification_service.dart';
import 'package:pbn/core/services/push_notification_service.dart';
import 'package:pbn/core/services/secure_storage.dart';
import 'package:pbn/core/services/chapter_service.dart';
import 'package:pbn/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Global auth state accessible via Provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ChapterService _chapterService = ChapterService();
  StreamSubscription? _sessionSubscription;

  AuthProvider() {
    // Listen for global session expiration (401 + failed refresh)
    _sessionSubscription = ApiClient.onSessionExpired.stream.listen((_) {
      debugPrint('AuthProvider: Detected expired session. Logging out.');
      logout();
    });
  }

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _loading = false;
  String? _error;
  String? _tfaToken;
  bool _requires2FA = false;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  String? get tfaToken => _tfaToken;
  bool get requires2FA => _requires2FA;

  /// Check if user has valid tokens on app start.
  Future<void> tryAutoLogin() async {
    _loading = true;
    notifyListeners();

    try {
      final hasTokens = await SecureStorage.hasTokens();
      if (hasTokens) {
        _user = await _authService.getProfile();
        
        // Fetch Chapter ID if not in profile
        if (_user?.chapterId == null) {
          try {
            final memberships = await _chapterService.getMyMemberships();
            if (memberships.isNotEmpty) {
              _user = _user?.copyWith(chapterId: memberships.first.chapter.id);
            }
          } catch (_) {}
        }

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

  /// Refresh user profile data (e.g., if role changed)
  Future<void> refreshProfile() async {
    if (_status != AuthStatus.authenticated) return;
    try {
      final user = await _authService.getProfile();
      _user = user;

      // Fetch Chapter ID if not in profile
      if (_user?.chapterId == null) {
        try {
          final memberships = await _chapterService.getMyMemberships();
          if (memberships.isNotEmpty) {
            _user = _user?.copyWith(chapterId: memberships.first.chapter.id);
          }
        } catch (_) {}
      }

      notifyListeners();
    } catch (_) {
      // If profile fetch fails with 401, logout
      await logout();
    }
  }

  /// Login with email/phone and password.
  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    _requires2FA = false;
    _tfaToken = null;
    notifyListeners();

    try {
      final data = await _authService.login(identifier, password);

      if (data['requires_2fa'] == true) {
        _tfaToken = data['tfa_token'];
        _requires2FA = true;
        _loading = false;
        notifyListeners();
        return false;
      }

      _user = await _authService.getProfile();

      // Fetch Chapter ID if not in profile
      if (_user?.chapterId == null) {
        try {
          final memberships = await _chapterService.getMyMemberships();
          if (memberships.isNotEmpty) {
            _user = _user?.copyWith(chapterId: memberships.first.chapter.id);
          }
        } catch (_) {}
      }

      _status = AuthStatus.authenticated;
      _registerFcmToken();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify 2FA code to complete login.
  Future<bool> verify2FA(String otp) async {
    if (_tfaToken == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verify2FA(_tfaToken!, otp);
      _user = await _authService.getProfile();

      // Fetch Chapter ID if not in profile
      if (_user?.chapterId == null) {
        try {
          final memberships = await _chapterService.getMyMemberships();
          if (memberships.isNotEmpty) {
            _user = _user?.copyWith(chapterId: memberships.first.chapter.id);
          }
        } catch (_) {}
      }

      _status = AuthStatus.authenticated;
      _requires2FA = false;
      _tfaToken = null;
      _registerFcmToken();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend 2FA code.
  Future<bool> resend2FA() async {
    if (_tfaToken == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resend2FA(_tfaToken!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle 2FA switch status.
  Future<bool> toggle2FA(bool enable, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedStatus = await _authService.toggle2FA(enable, password);
      _user = _user?.copyWith(twoFactorEnabled: updatedStatus);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
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
        debugPrint('FCM token registered: $token');
      }
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
