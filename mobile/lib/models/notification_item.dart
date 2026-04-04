class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final String sentAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    this.isRead = false,
    required this.sentAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        notificationType: json['notification_type'] ?? '',
        isRead: json['is_read'] ?? false,
        sentAt: json['sent_at'] ?? '',
        data: json['data'],
      );
}
