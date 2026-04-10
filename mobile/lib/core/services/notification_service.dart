import 'package:pbn/core/services/api_client.dart';
import 'package:pbn/models/notification_item.dart';

class NotificationService {
  final _api = ApiClient();

  Future<void> registerFcmToken(String fcmToken) async {
    await _api.post('/notifications/token', data: {'fcm_token': fcmToken});
  }

  Future<List<NotificationItem>> listNotifications() async {
    final res = await _api.get('/notifications');
    final data = _api.unwrap(res);
    final List<dynamic> list = data['notifications'] ?? [];
    return list.map((j) => NotificationItem.fromJson(j)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _api.get('/notifications/unread-count');
    final data = _api.unwrap(res);
    return data['count'] ?? 0;
  }

  Future<void> markRead(String notificationId) async {
    await _api.patch('/notifications/$notificationId/read');
  }


  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }
}
