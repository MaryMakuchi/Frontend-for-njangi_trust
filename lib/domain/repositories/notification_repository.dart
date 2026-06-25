import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markAsRead(String id);
  Future<int> getUnreadCount();
  Future<void> markAllAsRead();
  Future<void> registerDeviceToken(String token, {String platform});
  Future<void> unregisterDeviceToken(String token);
}
