import '../../core/utils/api_helper.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    super.profileImageUrl,
    super.mriScore,
    super.isKycVerified,
    super.groupsCount,
    super.yearsActive,
    super.globalRank,
    super.badge,
    super.walletBalance,
    super.savingsBalance,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      mriScore: parseDouble(json['mri_score']),
      isKycVerified: json['is_kyc_verified'] as bool? ?? false,
      groupsCount: json['groups_count'] as int? ?? 0,
      yearsActive: json['years_active'] as int? ?? 0,
      globalRank: json['global_rank'] as int? ?? 0,
      badge: json['badge'] as String?,
      walletBalance: parseDouble(json['wallet_balance']),
      savingsBalance: parseDouble(json['savings_balance']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'profile_image_url': profileImageUrl,
        'mri_score': mriScore,
        'is_kyc_verified': isKycVerified,
        'groups_count': groupsCount,
        'years_active': yearsActive,
        'global_rank': globalRank,
        'badge': badge,
        'wallet_balance': walletBalance,
        'savings_balance': savingsBalance,
      };
}
