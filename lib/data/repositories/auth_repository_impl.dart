import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_data.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    SecureStorageService? storage,
    ApiService? api,
  })  : _storage = storage ?? SecureStorageService(),
        _api = api ?? ApiService(storage: storage ?? SecureStorageService());

  final SecureStorageService _storage;
  final ApiService _api;

  Future<UserEntity> _saveAuthResponse(Map<String, dynamic> json) async {
    final tokens = json['tokens'] as Map<String, dynamic>;
    await _storage.saveToken(tokens['access'] as String);
    await _storage.saveRefreshToken(tokens['refresh'] as String);
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await _storage.saveUserId(user.id);
    return user;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    if (AppConstants.useMockData) return _mockLogin(email: email);

    final response = await _api.post(
      '/auth/login/',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return _saveAuthResponse(parseJsonResponse(response));
  }

  @override
  Future<UserEntity> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    if (AppConstants.useMockData) return _mockLogin(phone: phone);

    final response = await _api.post(
      '/auth/login/phone/',
      body: {'phone': phone, 'password': password},
      auth: false,
    );
    return _saveAuthResponse(parseJsonResponse(response));
  }

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (AppConstants.useMockData) {
      final user = UserEntity(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
      );
      await _storage.saveToken('mock_jwt_token');
      await _storage.saveUserId(user.id);
      return user;
    }

    final response = await _api.post(
      '/auth/register/',
      body: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      },
      auth: false,
    );
    return _saveAuthResponse(parseJsonResponse(response));
  }

  @override
  Future<void> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    if (AppConstants.useMockData) {
      if (otp != '123456' && otp.length != 6) throw Exception('Invalid OTP');
      return;
    }
    final response = await _api.post(
      '/auth/verify-phone/',
      body: {'phone': phone, 'otp': otp},
    );
    parseJsonResponse(response);
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    if (AppConstants.useMockData) {
      if (otp.length != 6) throw Exception('Invalid OTP');
      return;
    }
    final response = await _api.post(
      '/auth/verify-email/',
      body: {'email': email, 'otp': otp},
    );
    parseJsonResponse(response);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    if (AppConstants.useMockData) return;
    final response = await _api.post(
      '/auth/forgot-password/',
      body: {'email': email},
      auth: false,
    );
    parseJsonResponse(response);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (AppConstants.useMockData) return;
    final response = await _api.post(
      '/auth/change-password/',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    parseJsonResponse(response);
  }

  @override
  Future<void> logout() async {
    if (!AppConstants.useMockData) {
      try {
        await _api.post('/auth/logout/');
      } catch (_) {}
    }
    await _storage.clearAll();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    if (AppConstants.useMockData) return MockData.currentUser;

    final response = await _api.get('/auth/me/');
    return UserModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<bool> isAuthenticated() async {
    return (await _storage.getToken()) != null;
  }

  Future<UserEntity> _mockLogin({String? email, String? phone}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = MockData.currentUser.copyWith(
      email: email,
      phone: phone,
    );
    await _storage.saveToken('mock_jwt_token');
    await _storage.saveUserId(user.id);
    return user;
  }
}

extension on UserEntity {
  UserEntity copyWith({String? email, String? phone}) {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl,
      mriScore: mriScore,
      isKycVerified: isKycVerified,
      groupsCount: groupsCount,
      yearsActive: yearsActive,
      globalRank: globalRank,
      badge: badge,
    );
  }
}
