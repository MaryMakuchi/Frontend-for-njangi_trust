import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.mriScore = 0,
    this.isKycVerified = false,
    this.groupsCount = 0,
    this.yearsActive = 0,
    this.globalRank = 0,
    this.badge,
    this.walletBalance = 0,
    this.savingsBalance = 0,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final double mriScore;
  final bool isKycVerified;
  final int groupsCount;
  final int yearsActive;
  final int globalRank;
  final String? badge;
  final double walletBalance;
  final double savingsBalance;

  double get totalBalance => walletBalance + savingsBalance;

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        profileImageUrl,
        mriScore,
        isKycVerified,
        groupsCount,
        yearsActive,
        globalRank,
        badge,
        walletBalance,
        savingsBalance,
      ];
}
