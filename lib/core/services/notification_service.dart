import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/notification_repository.dart';

/// Firebase Cloud Messaging wrapper.
///
/// Everything here is best-effort and guarded: if Firebase isn't configured on
/// the device (no `google-services.json` / `GoogleService-Info.plist`), the
/// calls fail quietly and the rest of the app keeps working. Run
/// `flutterfire configure` to enable real push delivery.
class NotificationService {
  NotificationService(this._repository, {FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  String? _registeredToken;

  /// Request permission, register this device's token with the backend, and
  /// start listening for messages. [onOpen] is called when the user taps a
  /// push (including one that launched the app from terminated state).
  /// [onForeground] is called when a message arrives while the app is open and
  /// in the foreground (FCM does not show a system banner in that case).
  Future<void> initialize({
    void Function(RemoteMessage message)? onOpen,
    void Function(RemoteMessage message)? onForeground,
  }) async {
    try {
      debugPrint('[Push] initializing…');
      final settings = await _messaging.requestPermission(
          alert: true, badge: true, sound: true);
      debugPrint('[Push] permission: ${settings.authorizationStatus}');

      final token = await _messaging.getToken();
      debugPrint('[Push] FCM token: '
          '${token == null ? "NULL" : "${token.substring(0, 12)}…"}');
      if (token != null) {
        await _register(token);
      }
      _messaging.onTokenRefresh.listen(_register);

      FirebaseMessaging.onMessage.listen((m) => onForeground?.call(m));
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen?.call(m));
      final initial = await _messaging.getInitialMessage();
      if (initial != null) onOpen?.call(initial);
    } catch (e) {
      // Push unavailable (e.g. Firebase not configured) — degrade gracefully.
      debugPrint('[Push] notifications unavailable: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _repository.registerDeviceToken(token, platform: _platform());
      _registeredToken = token;
      debugPrint('[Push] device token registered with backend ✓');
    } catch (e) {
      debugPrint('[Push] could not register device token: $e');
    }
  }

  /// Stop this device receiving pushes for the current user (call on logout).
  Future<void> unregister() async {
    final token = _registeredToken ?? await _safeToken();
    if (token == null) return;
    try {
      await _repository.unregisterDeviceToken(token);
    } catch (_) {
      // Ignore — token will be reassigned on next login anyway.
    }
    _registeredToken = null;
  }

  Future<String?> _safeToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }
}
