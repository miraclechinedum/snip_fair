import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Concise notification service that
/// - initializes Firebase Messaging
/// - shows local notifications when the app is in the foreground
/// - exposes a broadcast stream so other layers (e.g., ConversationCubit)
///   can react to incoming notifications
/// - handles navigation based on notification type
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _updatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updates => _updatesController.stream;

  final _flnp = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Optional callback to handle navigation when notification is tapped
  /// Called with the notification data map containing 'type', 'type_identifier', etc.
  void Function(Map<String, dynamic> data)? onNotificationTap;

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
      badge: true,
    );

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('ic_launcher');
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
          // Navigate based on notification type
          _handleNotificationNavigation(map);
        } catch (e) {
          log('Error parsing notification payload: $e');
        }
      },
    );

    // Foreground messages: show local notif and emit to stream
    FirebaseMessaging.onMessage.listen((message) async {
      final data = _normalize(message);
      _updatesController.add(data);

      await _showLocalNotification(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: message.notification?.title ?? (data['title'] as String?),
        body: message.notification?.body ?? (data['body'] as String?),
        payload: jsonEncode(data),
      );
    });

    // Tapped notifications when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = _normalize(message);
      _updatesController.add(data);
      // Navigate when notification opened from background
      _handleNotificationNavigation(data);
    });

    // App launched by tapping a notification (terminated state)
    unawaited(_emitInitialMessageIfAny());

    _initialized = true;
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Check if navigation callback is set
    if (onNotificationTap == null) {
      log('NotificationService: onNotificationTap callback not set');
      return;
    }

    // Check if it's a silent notification (don't navigate for silent notifications)
    final silent = data['silent'];
    if (silent == '1' || silent == 1) {
      log('NotificationService: Silent notification, skipping navigation');
      return;
    }

    // Extract notification type and identifier
    final type = data['type'] as String?;
    final typeIdentifier = data['type_identifier'];

    if (type != null && type.isNotEmpty) {
      log('NotificationService: Navigating for type: $type, identifier: $typeIdentifier');
      onNotificationTap!(data);
    } else {
      log('NotificationService: No type found in notification data');
    }
  }

  Future<void> _emitInitialMessageIfAny() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final data = _normalize(initial);
        _updatesController.add(data);
        // Navigate when app opened from terminated state by notification
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService initial message error: $e');
      }
    }
  }

  Map<String, dynamic> _normalize(RemoteMessage m) {
    // Merge the notification (title/body) and custom data
    log('FCM Message Data: ${m.data}');
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

  Future<Map<String, dynamic>> getLastNotificationData() async {
    // get last notification from updates stream
    try {
      final completer = Completer<Map<String, dynamic>>();
      final sub = updates.listen(completer.complete);
      final data = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => <String, dynamic>{},
      );
      log('Last Notification Data: $data');
      await sub.cancel();
      return data;
    } catch (_) {
      return <String, dynamic>{};
    }
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
