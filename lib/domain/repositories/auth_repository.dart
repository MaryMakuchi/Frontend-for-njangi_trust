import '../entities/mri_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> loginWithPhone({
    required String phone,
    required String password,
  });
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> verifyPhone({required String phone, required String otp});
  Future<void> verifyEmail({required String email, required String otp});
  Future<void> forgotPassword({required String email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isAuthenticated();
  Future<MriHistoryEntity> getMriHistory();
}
