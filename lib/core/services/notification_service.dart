import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Concise notification service that
/// - initializes Firebase Messaging
/// - shows local notifications when the app is in the foreground
/// - exposes a broadcast stream so other layers (e.g., ConversationCubit)
///   can react to incoming notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _updatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updates => _updatesController.stream;

  final _flnp = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Ensure Firebase is initialized (safe to call multiple times)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // Ignore - it may already be initialized elsewhere in the app
    }

    // Ask for permission (iOS/macOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _flnp.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final map = json.decode(payload) as Map<String, dynamic>;
          _updatesController.add(map);
        } catch (_) {
          // ignore malformed payloads
        }
      },
    );

    // Foreground messages: show local notif and emit to stream
    FirebaseMessaging.onMessage.listen((message) async {
      final data = _normalize(message);
      _updatesController.add(data);

      await _showLocalNotification(
        id: message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: message.notification?.title ?? (data['title'] as String?),
        body: message.notification?.body ?? (data['body'] as String?),
        payload: jsonEncode(data),
      );
    });

    // Tapped notifications when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _updatesController.add(_normalize(message));
    });

    // App launched by tapping a notification (terminated state)
    unawaited(_emitInitialMessageIfAny());

    _initialized = true;
  }

  Future<void> _emitInitialMessageIfAny() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _updatesController.add(_normalize(initial));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService initial message error: $e');
      }
    }
  }

  Map<String, dynamic> _normalize(RemoteMessage m) {
    // Merge the notification (title/body) and custom data
    return <String, dynamic>{
      'title': m.notification?.title,
      'body': m.notification?.body,
      ...m.data,
    };
  }

  Future<void> _showLocalNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _flnp.show(id, title, body, details, payload: payload);
  }

  /// Optionally expose the current FCM token if needed by callers
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  void dispose() {
    _updatesController.close();
  }
}

/// If you want to handle background messages (app terminated/background),
/// define a top-level handler in your app entrypoint (main.dart):
///
/// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
///   await Firebase.initializeApp();
///   // You could schedule a local notification here if desired.
/// }
///
/// And register it very early in main():
/// FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
