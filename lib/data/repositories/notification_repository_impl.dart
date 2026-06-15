import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/mock_data.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    if (AppConstants.useMockData) return MockData.notifications;

    final response = await _api.get('/notifications/');
    return parseListResponse(response)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    if (AppConstants.useMockData) return;

    final response = await _api.patch('/notifications/$id/read/');
    parseJsonResponse(response);
  }

  @override
  Future<int> getUnreadCount() async {
    if (AppConstants.useMockData) {
      return MockData.notifications.where((n) => !n.isRead).length;
    }

    final response = await _api.get('/notifications/unread-count/');
    final data = parseJsonResponse(response);
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAllAsRead() async {
    if (AppConstants.useMockData) return;

    final response = await _api.post('/notifications/read-all/');
    parseJsonResponse(response);
  }

  @override
  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    if (AppConstants.useMockData) return;

    final response = await _api.post(
      '/notifications/devices/register/',
      body: {'token': token, 'platform': platform},
    );
    parseJsonResponse(response);
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    if (AppConstants.useMockData) return;

    final response = await _api.post(
      '/notifications/devices/unregister/',
      body: {'token': token},
    );
    parseJsonResponse(response);
  }
}
