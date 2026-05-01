import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'env_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      EnvConfig.debugPrint('Initializing Firebase Messaging...');

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      EnvConfig.debugPrint('Notification permissions: ${settings.authorizationStatus}');

      // Initialize local notifications for Android
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle message when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleBackgroundMessage(message);
      });

      // Handle background messages (when app is closed)
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

      // Get the device token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        EnvConfig.debugPrint('FCM Token: $token');
        // TODO: Send this token to your backend during user registration
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        EnvConfig.debugPrint('FCM Token refreshed: $newToken');
        // TODO: Update token on backend
      });
    } catch (e) {
      EnvConfig.debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    EnvConfig.debugPrint('Foreground message received: ${message.notification?.title}');

    // Show local notification when app is in foreground
    _showLocalNotification(
      title: message.notification?.title ?? 'HumanSafety Alert',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    EnvConfig.debugPrint('Background message clicked: ${message.notification?.title}');

    // Handle navigation based on message data
    final type = message.data['type'];

    if (type == 'case_assigned') {
      // Navigate to case details
      // Navigator would be called here if context is available
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'human_safety_notifications',
      'Emergency Notifications',
      channelDescription: 'Notifications for emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      sound: 'alarm.caf',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'human_safety',
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload != null ? payload.toString() : null,
    );
  }

  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    EnvConfig.debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    EnvConfig.debugPrint('Unsubscribed from topic: $topic');
  }
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  EnvConfig.debugPrint('Background message handled: ${message.notification?.title}');
  // Handle background message here
}
