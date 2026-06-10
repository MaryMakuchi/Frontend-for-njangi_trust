import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging wrapper. Requires Firebase initialization.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
  }

  Future<String?> getToken() => _messaging.getToken();

  void _onForegroundMessage(RemoteMessage message) {
    // Handle foreground notifications — integrate with in-app notification center.
  }

  void _onMessageOpened(RemoteMessage message) {
    // Navigate based on message.data payload.
  }
}
