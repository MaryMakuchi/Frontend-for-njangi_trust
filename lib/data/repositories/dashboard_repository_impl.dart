import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_cache.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/mock_data.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({ApiService? api, LocalCache? cache})
      : _api = api ?? ApiService(),
        _cache = cache ?? LocalCache();

  final ApiService _api;
  final LocalCache _cache;

  static const _cacheKey = 'dashboard';

  @override
  Future<DashboardEntity> getDashboard() async {
    if (AppConstants.useMockData) return MockData.dashboard;

    try {
      final response = await _api.get('/dashboard/');
      final json = parseJsonResponse(response);
      await _cache.writeJson(_cacheKey, json);
      return DashboardModel.fromJson(json);
    } catch (e) {
      // Offline-first fallback: serve the last-known dashboard if we have one.
      final cached = await _cache.readJson(_cacheKey);
      if (cached is Map<String, dynamic>) {
        return DashboardModel.fromJson(cached);
      }
      rethrow;
    }
  }
}
