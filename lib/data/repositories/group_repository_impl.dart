import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/mock_data.dart';
import '../models/group_model.dart';

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
}
