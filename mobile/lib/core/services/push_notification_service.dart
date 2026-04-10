import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbn/core/services/notification_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Root initialization (should be called in main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Firebase (Requires google-services.json / GoogleService-Info.plist)
    await Firebase.initializeApp();

    // 2. Request Permissions (iOS/MacOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Setup Local Notifications (for foreground messages)
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap when app is in foreground
        _handleNotificationTap(details.payload);
      },
    );

    // 4. Handle Incoming Messages
    
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Background Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['referral_id'] ?? message.data['application_id']);
    });

    // Terminated Tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['referral_id'] ?? initialMessage.data['application_id']);
    }

    _initialized = true;
  }

  /// Get FCM Token to register with backend
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Show a banner even if the app is open (Foreground)
  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'pbn_core_channel',
            'PBN Notifications',
            channelDescription: 'Main notification channel for PBN',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['referral_id'] ?? message.data['application_id'],
      );
    }
  }

  /// Navigate or perform action based on notification content
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    // TODO: Implement navigation logic (usually via a GlobalKey for Navigator or a deep-linking service)
    print("Notification tapped with payload: $payload");
  }

  /// Subscribe to specific user topic (optional but useful)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
