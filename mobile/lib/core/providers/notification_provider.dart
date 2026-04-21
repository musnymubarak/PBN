import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/core/services/push_notification_service.dart';

/// Holds notification badge count, accessible globally via Provider.
class NotificationProvider extends ChangeNotifier {
  final _api = ApiClient();
  int _unreadCount = 0;
  StreamSubscription? _pushSubscription;
  Timer? _pollTimer;

  int get unreadCount => _unreadCount;

  /// Start listening for real-time push notifications + periodic polling.
  void startListening() {
    // 1. Listen to foreground FCM messages — instant badge update
    _pushSubscription?.cancel();
    _pushSubscription = PushNotificationService.onMessageStream.listen((_) {
      // Immediately increment so the UI updates with zero delay
      _unreadCount++;
      notifyListeners();
      // Then sync with backend for accuracy
      fetchUnreadCount();
    });

    // 2. Poll every 30 seconds as a fallback for missed messages
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnreadCount();
    });
  }

  /// Stop all listeners (call on logout).
  void stopListening() {
    _pushSubscription?.cancel();
    _pushSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch unread count from backend.
  Future<void> fetchUnreadCount() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      final data = _api.unwrap(res);
      _unreadCount = data['count'] ?? 0;
      notifyListeners();
    } catch (_) {
      // Silently fail — badge is non-critical
    }
  }

  void clear() {
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
