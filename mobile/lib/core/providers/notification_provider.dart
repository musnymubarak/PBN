import 'package:flutter/material.dart';
import 'package:pbn/core/services/api_client.dart';

/// Holds notification badge count, accessible globally via Provider.
class NotificationProvider extends ChangeNotifier {
  final _api = ApiClient();
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

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
}
