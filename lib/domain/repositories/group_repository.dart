import '../entities/group_entity.dart';
import '../entities/group_message_entity.dart';
import '../entities/membership_request_entity.dart';
import '../entities/savings_entity.dart';
import '../entities/social_fund_entity.dart';

abstract class GroupRepository {
  Future<List<GroupEntity>> getGroups();
  Future<GroupEntity> getGroupById(String id);
  Future<GroupEntity> createGroup({
    required String name,
    required double contributionAmount,
    required String frequency,
    required int maxMembers,
    required DateTime startDate,
    String? rules,
    double? targetAmount,
    int durationMonths = 12,
    String pickingMode = 'random',
  });
  Future<String> joinGroup({String? invitationCode, String? groupId});
  Future<GroupEntity> assignPickingOrder({
    required String groupId,
    required String mode,
    List<String>? order,
  });
  Future<GroupEntity> updateGroupSettings({
    required String groupId,
    int? maxMembers,
  });
  Future<PlayNjangiResultEntity> playNjangi(String groupId);
  Future<List<SocialFundEntity>> getSocialFunds(String groupId);
  Future<SocialFundEntity> createSocialFund({
    required String groupId,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    double? targetAmount,
  });
  Future<SocialFundEntity> contributeSocialFund({
    required String groupId,
    required String fundId,
    required double amount,
  });
  Future<List<GroupMessageEntity>> getGroupMessages(String groupId);
  Future<GroupMessageEntity> sendGroupMessage({
    required String groupId,
    required String message,
  });

  // Group savings (#6, #7)
  Future<GroupSavingsEntity> getGroupSavings(String groupId);
  Future<SavingsPeriodEntity> startSavingsPeriod({
    required String groupId,
    required double interestRate,
    required String interestType,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<SavingsSummaryEntity> depositToGroupSavings({
    required String groupId,
    required double amount,
  });
  Future<SavingsWithdrawalResultEntity> withdrawGroupSavings(String groupId);
  Future<void> closeSavingsPeriod(String groupId);

  // Membership requests (#15)
  Future<List<MembershipRequestEntity>> getMembershipRequests(String groupId);
  Future<String> respondToMembershipRequest({
    required String groupId,
    required String requestId,
    required String decision,
  });
}
