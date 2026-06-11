import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_message_entity.dart';
import '../../domain/entities/social_fund_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/mock_data.dart';
import '../models/group_message_model.dart';
import '../models/group_model.dart';
import '../models/social_fund_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<GroupEntity>> getGroups() async {
    if (AppConstants.useMockData) return MockData.groups;

    final response = await _api.get('/groups/');
    return parseListResponse(response)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
      },
    );
    return GroupModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<GroupEntity> joinGroup({
    String? invitationCode,
    String? groupId,
  }) async {
    if (AppConstants.useMockData) {
      if (invitationCode != null) {
        return MockData.groups.firstWhere(
          (g) => g.invitationCode == invitationCode,
          orElse: () => throw Exception('Invalid invitation code'),
        );
      }
      return MockData.groups.firstWhere((g) => g.id == groupId);
    }

    final body = <String, dynamic>{};
    if (invitationCode != null) body['invitation_code'] = invitationCode;
    if (groupId != null) body['group_id'] = groupId;

    final response = await _api.post('/groups/join/', body: body);
    return GroupModel.fromJson(parseJsonResponse(response));
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
  Future<PlayNjangiResultEntity> playNjangi(String groupId) async {
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

    final response = await _api.post('/groups/$groupId/play/', body: const {});
    return PlayNjangiResultModel.fromJson(parseJsonResponse(response));
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
}
