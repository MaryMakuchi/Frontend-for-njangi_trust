import '../../core/utils/api_helper.dart';
import '../../domain/entities/social_fund_entity.dart';

class SocialFundModel {
  static SocialFundEntity fromJson(Map<String, dynamic> json) {
    final contributionsJson = json['contributions'] as List? ?? [];
    return SocialFundEntity(
      id: json['id'].toString(),
      groupId: json['group_id'].toString(),
      groupName: json['group_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      balance: parseDouble(json['balance']),
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      createdByName: json['created_by_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      targetAmount: json['target_amount'] != null ? parseDouble(json['target_amount']) : null,
      contributions: contributionsJson
          .map((c) => SocialFundContributionModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SocialFundContributionModel {
  static SocialFundContributionEntity fromJson(Map<String, dynamic> json) {
    return SocialFundContributionEntity(
      id: json['id'].toString(),
      userName: json['user_name'] as String? ?? '',
      amount: parseDouble(json['amount']),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }
}
