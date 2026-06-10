import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/mock_data.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<DashboardEntity> getDashboard() async {
    if (AppConstants.useMockData) return MockData.dashboard;

    final response = await _api.get('/dashboard/');
    return DashboardModel.fromJson(parseJsonResponse(response));
  }
}
