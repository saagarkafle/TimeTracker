import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/notifications.dart';

/// Top-level background message handler required by firebase_messaging.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For background messages, delegate to local notifications if needed.
  final notification = message.notification;
  if (notification != null) {
    await Notifications.showNotification(
      DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      notification.title ?? 'Notification',
      notification.body ?? '',
    );
  }
}

class PushService {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;

  /// Initialize messaging, request permissions, and register handlers.
  static Future<void> init() async {
    // register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions on iOS / Android 13+
    if (!kIsWeb) {
      if (Platform.isIOS) {
        final settings = await _fm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('iOS FCM permission: $settings');
      } else if (Platform.isAndroid) {
        // On Android 13+ we still need POST_NOTIFICATIONS runtime permission.
        // Requesting that is left to the app UI; firebase_messaging returns a token regardless on older OS.
        // Still call requestPermission() for consistency (no-op on many Android versions).
        final settings = await _fm.requestPermission();
        debugPrint('Android FCM permission: $settings');
      }
    }

    // Get and persist token
    final token = await _fm.getToken();
    if (token != null) {
      await _saveToken(token);
      debugPrint('FCM token: $token');
    }

    // token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveToken(newToken);
      debugPrint('FCM token refreshed: $newToken');
    });

    // Foreground messages: show as local notification or handle
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification != null) {
        await Notifications.showNotification(
          DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
          notification.title ?? 'Notification',
          notification.body ?? '',
        );
      }
    });

    // When the user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM onMessageOpenedApp: ${message.messageId}');
      // Optionally navigate or handle message
    });
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Returns the last-saved token or requests a fresh token if none saved.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('fcm_token');
    if (saved != null && saved.isNotEmpty) return saved;
    final token = await _fm.getToken();
    if (token != null) await _saveToken(token);
    return token;
  }

  /// For future: upload token to your server or Firestore to enable targeted pushes.
  static Future<void> uploadTokenForUser(String uid) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    try {
      final db = FirebaseFirestore.instance;
      await db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'platform': Platform.operatingSystem,
          });
      debugPrint('FCM token uploaded for user $uid');
    } catch (e) {
      debugPrint('Error uploading FCM token: $e');
    }
  }

  /// Optionally call an HTTPS Cloud Function to trigger a push when week paid.
  /// Provide a URL in `functionUrl` and the function should accept JSON { uid, weekKey, paid }
  static Future<void> notifyWeekPaid({
    required String uid,
    required String weekKey,
    required bool paid,
    String? functionUrl,
  }) async {
    if (functionUrl == null || functionUrl.isEmpty) return;
    try {
      // Simple POST to your cloud function; you may need to add auth headers.
      // We avoid adding `http` dependency here; leave implementation to the app owner.
      debugPrint(
        'Would call cloud function $functionUrl for user $uid week $weekKey paid=$paid',
      );
    } catch (e) {
      debugPrint('notifyWeekPaid error: $e');
    }
  }
}
