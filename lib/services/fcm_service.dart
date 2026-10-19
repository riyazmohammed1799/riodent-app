import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// Top-level background message handler invoked by FCM when the app is in the background or terminated.
///
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter's tree shaker does not remove it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('🔔 [FCM Background] Message received: ${message.messageId}');
  }
}

/// Production Firebase Cloud Messaging service for RioDent.
///
/// Features:
/// - Free tier (Spark plan) broadcast and targeted notification campaigns from Firebase Console.
/// - Graceful degradation on Web and platforms without Google Play services.
/// - Safe token handling (redacted in debug logs, never leaked in production).
/// - Dynamic deep-link routing when users tap notifications (e.g. to a specific service request).
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Initializes notification permissions, background handlers, and tap-to-navigate listeners.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Register top-level background handler on native platforms
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // 2. Request user notification permissions (required for Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}');
      }

      // 3. Register device token safely
      await _fetchAndLogToken();

      // 4. Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          final preview = newToken.length > 10 ? '${newToken.substring(0, 8)}...' : newToken;
          debugPrint('🔄 [FCM] Device token refreshed: $preview');
        }
      });

      // 5. Subscribe to general broadcast topics for free console campaigns
      if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic('all_users');
          await _messaging.subscribeToTopic('announcements');
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [FCM] Topic subscription notice: $e');
          }
        }
      }

      // 6. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('💬 [FCM Foreground] ${message.notification?.title}: ${message.notification?.body}');
        }
      });

      // 7. Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 8. Handle notification tap that launched the app from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('⚠️ [FCM] Non-fatal initialization notice: $e\n$stack');
      }
    }
  }

  /// Safely obtains the FCM device token and logs a redacted snippet in debug mode.
  static Future<String?> _fetchAndLogToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && kDebugMode) {
        final preview = token.length > 10 ? '${token.substring(0, 8)}...' : token;
        debugPrint('📱 [FCM] Token ready: $preview');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [FCM] Could not retrieve device token: $e');
      }
      return null;
    }
  }

  /// Returns the current device token (e.g. to associate with the user profile in Firestore).
  static Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Routes the user to the relevant screen when a notification is tapped.
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('👉 [FCM] Notification tapped. Data: ${message.data}');
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    // Direct route payload takes priority (e.g. data: {"route": "/dentist/requests/req_123"})
    final explicitRoute = message.data['route'];
    if (explicitRoute is String && explicitRoute.isNotEmpty) {
      context.push(explicitRoute);
      return;
    }

    // Specific request ID payload (e.g. data: {"requestId": "req_123"})
    final requestId = message.data['requestId'];
    if (requestId is String && requestId.isNotEmpty) {
      context.push('/dentist/requests/$requestId');
    }
  }
}
