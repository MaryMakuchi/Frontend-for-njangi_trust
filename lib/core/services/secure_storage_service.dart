import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.jwtTokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: AppConstants.jwtTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: AppConstants.userIdKey, value: userId);

  Future<String?> getUserId() => _storage.read(key: AppConstants.userIdKey);

  Future<void> savePin(String pin) =>
      _storage.write(key: AppConstants.pinKey, value: pin);

  Future<String?> getPin() => _storage.read(key: AppConstants.pinKey);

  Future<void> setBiometricsEnabled(bool enabled) => _storage.write(
        key: AppConstants.biometricsEnabledKey,
        value: enabled.toString(),
      );

  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: AppConstants.biometricsEnabledKey);
    return value == 'true';
  }

  Future<void> clearAll() => _storage.deleteAll();
}
