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
}
