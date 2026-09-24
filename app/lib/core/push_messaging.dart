import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'locale_controller.dart';

/// Android notification channel for waylo pushes. Importance.high makes them
/// appear as a heads-up banner even while the app is in the foreground.
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'waylo_default',
  'waylo',
  description: 'Friend requests, likes and comments',
  importance: Importance.high,
);

/// Render a waylo push as a system notification. The Edge Function sends
/// **data-only** messages (title/body in `data`) so the OS never auto-displays
/// them; we draw every notification ourselves, in both the foreground and the
/// background isolate. This lets us set the real app launcher icon as the
/// `largeIcon` — so the notification carries the exact sky-blue brand icon from
/// the home screen instead of the OS-tinted (darkened) silhouette. The small
/// status-bar icon stays the white 'm' silhouette (`ic_stat_waylo`).
Future<void> showWayloNotification(RemoteMessage message) async {
  final data = message.data;
  final title = data['title'];
  final body = data['body'];
  if (title == null && body == null) return;

  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_channel);

  await local.show(
    (data['post_id'] ?? title ?? body).hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_waylo',
      ),
    ),
  );
}

/// Background / terminated isolate entry point. Must be a top-level function
/// annotated with `vm:entry-point`; registered via [FirebaseMessaging
/// .onBackgroundMessage] in `main`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await showWayloNotification(message);
}

/// FCM registration: asks notification permission, saves the device token to
/// Supabase (`register_device_token` RPC), and keeps it fresh on refresh.
/// Android-first; iOS push is deferred (no APNs yet), so failures are swallowed
/// — push is a nice-to-have that must never block the app.
class PushMessaging {
  PushMessaging._();
  static final PushMessaging instance = PushMessaging._();

  bool _wired = false;
  bool _foregroundWired = false;

  /// Call once the user is signed in (safe to call repeatedly).
  Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _wireForeground();
      final token = await messaging.getToken();
      if (token != null) await _save(token);
      if (!_wired) {
        _wired = true;
        messaging.onTokenRefresh.listen(_save);
        // Re-save on a language switch so pushes follow it right away, not only
        // after the next launch.
        LocaleController.instance.addListener(_resave);
      }
    } catch (e) {
      debugPrint('[push] register failed: $e');
    }
  }

  Future<void> _resave() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(token);
    } catch (e) {
      debugPrint('[push] token resave failed: $e');
    }
  }

  /// Draw pushes that arrive while the app is in the foreground (the background
  /// isolate handles the rest via [firebaseMessagingBackgroundHandler]).
  void _wireForeground() {
    if (_foregroundWired) return;
    _foregroundWired = true;
    FirebaseMessaging.onMessage.listen(showWayloNotification);
  }

  Future<void> _save(String token) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;
    try {
      await client.rpc(
        'register_device_token',
        params: {
          'p_token': token,
          'p_platform': 'android',
          // The recipient's app language, so the Edge Function localizes the push.
          'p_language': LocaleController.instance.resolvedLanguageCode,
        },
      );
    } catch (e) {
      debugPrint('[push] token save failed: $e');
    }
  }
}
