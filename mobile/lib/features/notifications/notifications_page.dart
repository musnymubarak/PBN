import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/providers/notification_provider.dart';
import 'package:pbn/core/services/notification_service.dart';
import 'package:pbn/models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadNotifications(); }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try { _notifications = await _service.listNotifications(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(String id) async {
    try {
      await _service.markRead(id);
      setState(() { _notifications = _notifications.map((n) => n.id == id ? NotificationItem(id: n.id, title: n.title, body: n.body, notificationType: n.notificationType, isRead: true, sentAt: n.sentAt, data: n.data) : n).toList(); });
      if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      setState(() { _notifications = _notifications.map((n) => NotificationItem(id: n.id, title: n.title, body: n.body, notificationType: n.notificationType, isRead: true, sentAt: n.sentAt, data: n.data)).toList(); });
      if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      setState(() { _notifications.removeWhere((n) => n.id == id); });
      if (mounted) context.read<NotificationProvider>().fetchUnreadCount();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (unread > 0) TextButton(onPressed: _markAllRead, child: const Text('Mark All Read', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(TablerIcons.bell_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No notifications', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) => _buildNotificationCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notif) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
        child: const Icon(TablerIcons.trash, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteNotification(notif.id),
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) _markRead(notif.id);
          
          final route = notif.data?['route'];
          print("DEBUG: Tapped notification. Data: ${notif.data}, Route found: $route");
          if (route != null) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(14),
            border: notif.isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (notif.isRead ? Colors.grey : AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(TablerIcons.bell, size: 20, color: notif.isRead ? Colors.grey : AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Text(notif.body, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(notif.sentAt.split('T').first, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ])),
            if (!notif.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }
}
