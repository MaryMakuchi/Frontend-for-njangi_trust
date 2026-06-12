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
      targetAmount: json['target_amount'] != null ? parseDouble(json['target_amount']) : null,
      durationMonths: json['duration_months'] != null ? parseInt(json['duration_months']) : 12,
      pickingMode: json['picking_mode'] as String? ?? 'random',
      scheduleGenerated: json['schedule_generated'] as bool? ?? false,
      pickersPerCycle: json['pickers_per_cycle'] != null ? parseInt(json['pickers_per_cycle']) : 1,
      endDate: parseDateTime(json['end_date']),
      currentPicker: json['current_picker'] != null
          ? CurrentPickerModel.fromJson(json['current_picker'] as Map<String, dynamic>)
          : null,
      rotationStarted: json['rotation_started'] as bool? ?? false,
    );
  }
}

class GroupSearchResultModel {
  static GroupSearchResultEntity fromJson(Map<String, dynamic> json) {
    return GroupSearchResultEntity(
      id: json['id'].toString(),
      name: json['name'] as String,
      memberCount: parseInt(json['member_count']),
      maxMembers: parseInt(json['max_members']),
    );
  }
}

class PlayNjangiResultModel {
  static PlayNjangiResultEntity fromJson(Map<String, dynamic> json) {
    return PlayNjangiResultEntity(
      amount: parseDouble(json['amount']),
      groupFundBalance: parseDouble(json['group_fund_balance']),
      cycleProgress: parseInt(json['cycle_progress']),
      maxMembers: parseInt(json['max_members']),
      currentPicker: json['current_picker'] != null
          ? CurrentPickerModel.fromJson(json['current_picker'] as Map<String, dynamic>)
          : null,
      cycleCompleted: json['cycle_completed'] as bool? ?? false,
      payout: json['payout'] != null
          ? PlayNjangiPayoutModel.fromJson(json['payout'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlayNjangiPayoutModel {
  static PlayNjangiPayoutEntity fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'] as Map<String, dynamic>?;
    return PlayNjangiPayoutEntity(
      amount: parseDouble(json['amount']),
      recipientId: recipient?['id']?.toString() ?? '',
      recipientName: recipient?['name'] as String? ?? '',
      transactionHash: json['transaction_hash'] as String?,
    );
  }
}

class CurrentPickerModel {
  static CurrentPickerEntity fromJson(Map<String, dynamic> json) {
    return CurrentPickerEntity(
      id: json['id'].toString(),
      name: json['name'] as String,
      rotationPosition: json['rotation_position'] != null
          ? parseInt(json['rotation_position'])
          : null,
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
      pickCycle: json['pick_cycle'] != null ? parseInt(json['pick_cycle']) : null,
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
