import '../../core/utils/api_helper.dart';
import '../../domain/entities/group_entity.dart';

class GroupModel {
  static GroupEntity fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List? ?? [];
    return GroupEntity(
      id: json['id'].toString(),
      name: json['name'] as String,
      memberCount: parseInt(json['member_count']),
      maxMembers: parseInt(json['max_members']),
      contributionAmount: parseDouble(json['contribution_amount']),
      frequency: json['frequency'] as String? ?? 'Monthly',
      fundBalance: parseDouble(json['fund_balance']),
      cycleProgress: parseInt(json['cycle_progress']),
      averageMri: parseDouble(json['average_mri']),
      startDate: parseDate(json['start_date']),
      invitationCode: json['invitation_code'] as String?,
      rules: json['rules'] as String?,
      members: membersJson.map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>)).toList(),
      currentBeneficiaryId: json['current_beneficiary_id']?.toString(),
      nextBeneficiaryId: json['next_beneficiary_id']?.toString(),
    );
  }
}

class GroupMemberModel {
  static GroupMemberEntity fromJson(Map<String, dynamic> json) {
    return GroupMemberEntity(
      id: json['id'].toString(),
      name: json['name'] as String,
      role: _parseRole(json['role'] as String?),
      mriScore: parseDouble(json['mri_score']),
      isCurrentBeneficiary: json['is_current_beneficiary'] as bool? ?? false,
      rotationPosition: json['rotation_position'] != null
          ? parseInt(json['rotation_position'])
          : null,
    );
  }

  static GroupRole _parseRole(String? role) {
    switch (role) {
      case 'president':
        return GroupRole.president;
      case 'treasurer':
        return GroupRole.treasurer;
      default:
        return GroupRole.member;
    }
  }
}
