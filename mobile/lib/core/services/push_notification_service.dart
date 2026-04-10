import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbn/core/services/notification_service.dart';

class PushNotificationService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _notifService = NotificationService();
  
  static bool _initialized = false;

  /// Root initialization (should be called in main.dart)
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    // Firebase Messaging is only supported on Android/iOS/Web
    // Skipping initialization on Windows/Desktop to prevent crashes
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS) {
      debugPrint("Push Notifications skip: Not on Mobile/Web");
      _initialized = true;
      return;
    }

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
        if (details.payload != null) {
          _navigateByNotificationData({'route': details.payload});
        }
      },
    );

    // 4. Handle Incoming Messages
    
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Background Tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Terminated Tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
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
        payload: message.data['route'],
      );
    }
  }

  /// Deep linking and state management when notification is tapped
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint("Notification Tapped: ${message.messageId}");
    
    // 1. Mark as read on backend (Fire and forget)
    final String? dbId = message.data['id'] ?? message.data['notification_id'];
    if (dbId != null) {
      _notifService.markRead(dbId).catchError((_) => null);
    }

    // 2. Navigation
    _navigateByNotificationData(message.data);
  }

  static void _navigateByNotificationData(Map<String, dynamic> data) {
    if (_navigatorKey == null) return;
    
    final route = data['route'];
    if (route != null) {
      _navigatorKey!.currentState?.pushNamed(route);
    } else {
      // Default fallback
      _navigatorKey!.currentState?.pushNamed('/notifications');
    }
  }

  /// Subscribe to specific user topic (optional but useful)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
}
