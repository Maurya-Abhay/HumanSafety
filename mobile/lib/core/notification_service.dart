import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'env_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      EnvConfig.debugPrint('Initializing local notifications...');

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
    } catch (e) {
      EnvConfig.debugPrint('Error initializing notifications: $e');
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

  Future<void> showEmergencyAlert({required String title, required String body}) async {
    await _showLocalNotification(title: title, body: body);
  }

  Future<String?> getDeviceToken() async {
    // Firebase Messaging removed from this build; no cloud token available.
    return null;
  }

  Future<void> subscribeToTopic(String topic) async {
    EnvConfig.debugPrint('Topic subscription skipped (Firebase not enabled): $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    EnvConfig.debugPrint('Topic unsubscribe skipped (Firebase not enabled): $topic');
  }
}
