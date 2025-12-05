import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'trackmyshift_channel';
  static const String _channelName = 'TrackMyShift';

  /// Initialize notifications. Call early in `main()`.
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(initSettings);

    // Create a default channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications for check-in / check-out / payments',
      importance: Importance.defaultImportance,
    );

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Notification channel create failed: $e');
      }
    }
  }

  static NotificationDetails _platformDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications for check-ins and payments',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Show a simple notification.
  static Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    try {
      await _plugin.show(id, title, body, _platformDetails());
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('showNotification error: $e');
      }
    }
  }
}
