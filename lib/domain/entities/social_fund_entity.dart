import 'package:equatable/equatable.dart';

class SocialFundContributionEntity extends Equatable {
  const SocialFundContributionEntity({
    required this.id,
    required this.userName,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final double amount;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userName, amount, createdAt];
}

class SocialFundEntity extends Equatable {
  const SocialFundEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.reason,
    required this.balance,
    required this.startDate,
    required this.endDate,
    required this.createdByName,
    required this.isActive,
    this.targetAmount,
    this.contributions = const [],
  });

  final String id;
  final String groupId;
  final String groupName;
  final String reason;
  final double balance;
  final DateTime startDate;
  final DateTime endDate;
  final String createdByName;
  final bool isActive;
  final double? targetAmount;
  final List<SocialFundContributionEntity> contributions;

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        reason,
        balance,
        startDate,
        endDate,
        createdByName,
        isActive,
        targetAmount,
        contributions,
      ];
}
