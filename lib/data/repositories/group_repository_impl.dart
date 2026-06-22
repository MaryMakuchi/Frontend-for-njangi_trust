import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_cache.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/due_date_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_message_entity.dart';
import '../../domain/entities/group_preview_entity.dart';
import '../../domain/entities/membership_request_entity.dart';
import '../../domain/entities/savings_entity.dart';
import '../../domain/entities/social_fund_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/mock_data.dart';
import '../models/due_date_model.dart';
import '../models/group_message_model.dart';
import '../models/group_model.dart';
import '../models/group_preview_model.dart';
import '../../domain/entities/reconciliation_entity.dart';
import '../models/membership_request_model.dart';
import '../models/reconciliation_model.dart';
import '../models/savings_model.dart';
import '../models/social_fund_model.dart';
import '../models/transaction_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({ApiService? api, LocalCache? cache})
      : _api = api ?? ApiService(),
        _cache = cache ?? LocalCache();

  final ApiService _api;
  final LocalCache _cache;

  static const _groupsCacheKey = 'groups';

  @override
  Future<List<GroupEntity>> getGroups() async {
    if (AppConstants.useMockData) return MockData.groups;

    try {
      final response = await _api.get('/groups/');
      final list = parseListResponse(response);
      await _cache.writeJson(_groupsCacheKey, list);
      return list
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Offline-first fallback: serve the last-known groups if we have them.
      final cached = await _cache.readJson(_groupsCacheKey);
      if (cached is List) {
        return cached
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<GroupEntity> getGroupById(String id) async {
    if (AppConstants.useMockData) {
      return MockData.groups.firstWhere((g) => g.id == id);
    }

    final response = await _api.get('/groups/$id/');
    return GroupModel.fromJson(parseJsonResponse(response));
  }

  @override
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
    String? playFrequency,
    int? playWeekday,
    String? playWeekOfMonth,
    String? playDeadlineTime,
  }) async {
    if (AppConstants.useMockData) {
      return GroupEntity(
        id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        memberCount: 1,
        maxMembers: maxMembers,
        contributionAmount: contributionAmount,
        frequency: frequency,
        fundBalance: 0,
        cycleProgress: 0,
        averageMri: 9.4,
        startDate: startDate,
        rules: rules,
        targetAmount: targetAmount,
        durationMonths: durationMonths,
        pickingMode: pickingMode,
        playFrequency: playFrequency,
        playWeekday: playWeekday,
        playWeekOfMonth: playWeekOfMonth,
        playDeadlineTime: playDeadlineTime,
      );
    }

    final response = await _api.post(
      '/groups/',
      body: {
        'name': name,
        'contribution_amount': contributionAmount,
        'frequency': frequency,
        'max_members': maxMembers,
        'start_date': startDate.toIso8601String().split('T').first,
        if (rules != null && rules.isNotEmpty) 'rules': rules,
        if (targetAmount != null) 'target_amount': targetAmount,
        'duration_months': durationMonths,
        'picking_mode': pickingMode,
        ...GroupModel.scheduleToJson(
          playFrequency: playFrequency,
          playWeekday: playWeekday,
          playWeekOfMonth: playWeekOfMonth,
          playDeadlineTime: playDeadlineTime,
        ),
      },
    );
    return GroupModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<String> joinGroup({
    String? invitationCode,
    String? groupId,
  }) async {
    if (AppConstants.useMockData) {
      return 'Membership request sent. Waiting for approval.';
    }

    final body = <String, dynamic>{};
    if (invitationCode != null) body['invitation_code'] = invitationCode;
    if (groupId != null) body['group_id'] = groupId;

    final response = await _api.post('/groups/join/', body: body);
    final json = parseJsonResponse(response);
    return json['detail'] as String? ?? 'Membership request sent. Waiting for approval.';
  }

  @override
  Future<List<GroupSearchResultEntity>> searchGroups(String query) async {
    if (AppConstants.useMockData) return [];

    if (query.trim().isEmpty) return [];

    final response = await _api.get('/groups/search/?q=${Uri.encodeQueryComponent(query.trim())}');
    return parseListResponse(response)
        .map((e) => GroupSearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupEntity> assignPickingOrder({
    required String groupId,
    required String mode,
    List<String>? order,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.groups.firstWhere((g) => g.id == groupId);
    }

    final response = await _api.post(
      '/groups/$groupId/picking-order/',
      body: {
        'mode': mode,
        if (order != null) 'order': order,
      },
    );
    return GroupModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<GroupEntity> updateGroupSettings({
    required String groupId,
    int? maxMembers,
    String? playFrequency,
    int? playWeekday,
    String? playWeekOfMonth,
    String? playDeadlineTime,
  }) async {
    if (AppConstants.useMockData) {
      final group = MockData.groups.firstWhere((g) => g.id == groupId);
      return GroupEntity(
        id: group.id,
        name: group.name,
        memberCount: group.memberCount,
        maxMembers: maxMembers ?? group.maxMembers,
        contributionAmount: group.contributionAmount,
        frequency: group.frequency,
        fundBalance: group.fundBalance,
        cycleProgress: group.cycleProgress,
        averageMri: group.averageMri,
        startDate: group.startDate,
        endDate: group.endDate,
        invitationCode: group.invitationCode,
        rules: group.rules,
        members: group.members,
        currentBeneficiaryId: group.currentBeneficiaryId,
        nextBeneficiaryId: group.nextBeneficiaryId,
        currentPicker: group.currentPicker,
        targetAmount: group.targetAmount,
        durationMonths: group.durationMonths,
        pickingMode: group.pickingMode,
        scheduleGenerated: group.scheduleGenerated,
        pickersPerCycle: group.pickersPerCycle,
      );
    }

    final response = await _api.patch(
      '/groups/$groupId/',
      body: {
        if (maxMembers != null) 'max_members': maxMembers,
        ...GroupModel.scheduleToJson(
          playFrequency: playFrequency,
          playWeekday: playWeekday,
          playWeekOfMonth: playWeekOfMonth,
          playDeadlineTime: playDeadlineTime,
        ),
      },
    );
    return GroupModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<PlayNjangiResultEntity> playNjangi(
    String groupId, {
    String source = 'wallet',
    String? linkedAccountId,
  }) async {
    if (AppConstants.useMockData) {
      final group = MockData.groups.firstWhere((g) => g.id == groupId);
      return PlayNjangiResultEntity(
        amount: group.contributionAmount,
        groupFundBalance: group.fundBalance + group.contributionAmount,
        cycleProgress: group.cycleProgress + 1,
        maxMembers: group.maxMembers,
        currentPicker: group.currentPicker,
      );
    }

    final response = await _api.post(
      '/groups/$groupId/play/',
      body: {
        'source': source,
        if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
      },
    );
    return PlayNjangiResultModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<List<DueDateEntity>> getDueDates({String horizon = '3m'}) async {
    if (AppConstants.useMockData) {
      final now = DateTime.now();
      return [
        DueDateEntity(
          type: 'njangi',
          label: 'Njangi - Family Savings',
          groupId: 'grp_mock',
          groupName: 'Family Savings',
          amount: 5000,
          dueDatetime: now.add(const Duration(days: 3)),
        ),
      ];
    }

    final response = await _api.get('/groups/due-dates/?horizon=$horizon');
    final json = parseJsonResponse(response);
    final list = json['due_dates'] as List? ?? const [];
    return list
        .map((e) => DueDateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupPreviewEntity> getGroupPreview(String groupId) async {
    if (AppConstants.useMockData) {
      final group = MockData.groups.firstWhere((g) => g.id == groupId);
      return GroupPreviewEntity(
        id: group.id,
        name: group.name,
        rules: group.rules,
        contributionAmount: group.contributionAmount,
        maxMembers: group.maxMembers,
        memberCount: group.memberCount,
        playFrequency: group.playFrequency,
        nextPlayDue: group.nextPlayDue,
        presidentName: null,
        isMember: false,
        hasPendingRequest: false,
      );
    }

    final response = await _api.get('/groups/$groupId/preview/');
    return GroupPreviewModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<List<TransactionEntity>> getGroupLedger(
    String groupId, {
    String category = 'all',
  }) async {
    if (AppConstants.useMockData) return [];

    final response = await _api.get('/groups/$groupId/ledger/?category=$category');
    return parseListResponse(response)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReconciliationEntity> getReconciliation(String groupId) async {
    final response = await _api.get('/groups/$groupId/reconciliation/');
    return ReconciliationModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<List<SocialFundEntity>> getSocialFunds(String groupId) async {
    if (AppConstants.useMockData) return [];

    final response = await _api.get('/groups/$groupId/social-fund/');
    return parseListResponse(response)
        .map((e) => SocialFundModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SocialFundEntity> createSocialFund({
    required String groupId,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    double? targetAmount,
  }) async {
    if (AppConstants.useMockData) {
      return SocialFundEntity(
        id: 'fund_${DateTime.now().millisecondsSinceEpoch}',
        groupId: groupId,
        groupName: '',
        reason: reason,
        balance: 0,
        startDate: startDate,
        endDate: endDate,
        createdByName: '',
        isActive: true,
        targetAmount: targetAmount,
      );
    }

    final response = await _api.post(
      '/groups/$groupId/social-fund/',
      body: {
        'reason': reason,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        if (targetAmount != null) 'target_amount': targetAmount,
      },
    );
    return SocialFundModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<SocialFundEntity> contributeSocialFund({
    required String groupId,
    required String fundId,
    required double amount,
  }) async {
    if (AppConstants.useMockData) {
      return SocialFundEntity(
        id: fundId,
        groupId: groupId,
        groupName: '',
        reason: '',
        balance: amount,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdByName: '',
        isActive: true,
      );
    }

    final response = await _api.post(
      '/groups/$groupId/social-fund/$fundId/contribute/',
      body: {'amount': amount},
    );
    return SocialFundModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<List<GroupMessageEntity>> getGroupMessages(String groupId) async {
    if (AppConstants.useMockData) return [];

    final response = await _api.get('/groups/$groupId/messages/');
    return parseListResponse(response)
        .map((e) => GroupMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GroupMessageEntity> sendGroupMessage({
    required String groupId,
    required String message,
  }) async {
    if (AppConstants.useMockData) {
      return GroupMessageEntity(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        groupId: groupId,
        userId: 'me',
        userName: 'Me',
        message: message,
        createdAt: DateTime.now(),
      );
    }

    final response = await _api.post(
      '/groups/$groupId/messages/',
      body: {'message': message},
    );
    return GroupMessageModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<GroupSavingsEntity> getGroupSavings(String groupId) async {
    if (AppConstants.useMockData) {
      return const GroupSavingsEntity(period: null, mySavings: null);
    }

    final response = await _api.get('/groups/$groupId/savings/');
    return GroupSavingsModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<SavingsPeriodEntity> startSavingsPeriod({
    required String groupId,
    required double interestRate,
    required String interestType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (AppConstants.useMockData) {
      return SavingsPeriodEntity(
        id: 'period_${DateTime.now().millisecondsSinceEpoch}',
        interestRate: interestRate,
        interestType: interestType,
        startDate: startDate,
        endDate: endDate,
        status: 'active',
        isClosed: false,
      );
    }

    final response = await _api.post(
      '/groups/$groupId/savings/start/',
      body: {
        'interest_rate': interestRate.toStringAsFixed(2),
        'interest_type': interestType,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
      },
    );
    return SavingsPeriodModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<SavingsSummaryEntity> depositToGroupSavings({
    required String groupId,
    required double amount,
    String source = 'wallet',
  }) async {
    if (AppConstants.useMockData) {
      return SavingsSummaryEntity(
        principal: amount,
        interestAccrued: 0,
        total: amount,
        deposits: [SavingsDepositEntity(amount: amount, date: DateTime.now())],
      );
    }

    final response = await _api.post(
      '/groups/$groupId/savings/deposit/',
      body: {'amount': amount.toStringAsFixed(2), 'source': source},
    );
    final json = parseJsonResponse(response);
    final mySavings = json['my_savings'] as Map<String, dynamic>? ?? json;
    return SavingsSummaryModel.fromJson(mySavings);
  }

  @override
  Future<SavingsWithdrawalResultEntity> withdrawGroupSavings(String groupId) async {
    if (AppConstants.useMockData) {
      return const SavingsWithdrawalResultEntity(
        amountWithdrawn: 0,
        newWalletBalance: 0,
      );
    }

    final response = await _api.post('/groups/$groupId/savings/withdraw/', body: const {});
    return SavingsWithdrawalResultModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<void> closeSavingsPeriod(String groupId) async {
    if (AppConstants.useMockData) return;

    await _api.post('/groups/$groupId/savings/close/', body: const {});
  }

  @override
  Future<List<MembershipRequestEntity>> getMembershipRequests(String groupId) async {
    if (AppConstants.useMockData) return [];

    final response = await _api.get('/groups/$groupId/membership-requests/');
    return parseListResponse(response)
        .map((e) => MembershipRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> respondToMembershipRequest({
    required String groupId,
    required String requestId,
    required String decision,
  }) async {
    if (AppConstants.useMockData) {
      return decision == 'accept' ? 'accepted' : 'rejected';
    }

    final response = await _api.post(
      '/groups/$groupId/membership-requests/$requestId/respond/',
      body: {'decision': decision},
    );
    final json = parseJsonResponse(response);
    return json['status'] as String? ?? '';
  }

  @override
  Future<void> startElection(String groupId) async {
    await _api.post('/groups/$groupId/election/start/', body: const {});
  }

  @override
  Future<ElectionEntity?> getElection(String groupId) async {
    final response = await _api.get('/groups/$groupId/election/');
    final json = parseJsonResponse(response);
    // If election key exists and is null, no active election
    if (json.containsKey('election') && json['election'] == null) return null;
    return ElectionModel.fromJson(json);
  }

  @override
  Future<void> nominateForElection({
    required String groupId,
    required String nomineeUsername,
    required String role,
  }) async {
    await _api.post(
      '/groups/$groupId/election/nominate/',
      body: {'nominee_username': nomineeUsername, 'role': role},
    );
  }

  @override
  Future<void> advanceElection(String groupId) async {
    await _api.post('/groups/$groupId/election/advance/', body: const {});
  }

  @override
  Future<void> voteInElection({
    required String groupId,
    required String nomineeId,
    required String role,
  }) async {
    await _api.post(
      '/groups/$groupId/election/vote/',
      body: {'nominee_id': nomineeId, 'role': role},
    );
  }

  @override
  Future<List<UserSearchResultEntity>> searchUsers(String query) async {
    final response = await _api.get('/groups/users/search/?q=${Uri.encodeQueryComponent(query)}');
    final json = parseJsonResponse(response);
    final results = json['results'] as List? ?? [];
    return results
        .map((e) => UserSearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GroupSlotEntity>> getMySlots(String groupId) async {
    final response = await _api.get('/groups/$groupId/my-slots/');
    final json = parseJsonResponse(response);
    final slots = json['slots'] as List? ?? [];
    return slots
        .map((e) => GroupSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
