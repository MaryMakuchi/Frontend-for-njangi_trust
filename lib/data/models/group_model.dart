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
      playFrequency: json['play_frequency'] as String?,
      playWeekday: json['play_weekday'] != null ? parseInt(json['play_weekday']) : null,
      playWeekOfMonth: json['play_week_of_month'] as String?,
      playDeadlineTime: json['play_deadline_time'] as String?,
      nextPlayDue: parseDateTime(json['next_play_due']),
    );
  }

  /// Serializes the schedule fields for create/patch payloads. Only includes
  /// fields that are non-null so callers can send partial updates.
  static Map<String, dynamic> scheduleToJson({
    String? playFrequency,
    int? playWeekday,
    String? playWeekOfMonth,
    String? playDeadlineTime,
  }) {
    return {
      if (playFrequency != null) 'play_frequency': playFrequency,
      if (playWeekday != null) 'play_weekday': playWeekday,
      if (playWeekOfMonth != null) 'play_week_of_month': playWeekOfMonth,
      if (playDeadlineTime != null) 'play_deadline_time': playDeadlineTime,
    };
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
      slotName: json['slot_name'] as String? ?? '',
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
      case 'vice_president':
        return GroupRole.vicePresident;
      case 'treasurer':
        return GroupRole.treasurer;
      case 'secretary':
        return GroupRole.secretary;
      case 'auditor':
        return GroupRole.auditor;
      default:
        return GroupRole.member;
    }
  }
}

class ElectionModel {
  static ElectionEntity? fromJson(Map<String, dynamic> json) {
    // The API returns {election: null} when no election is active
    if (json['election'] == null && !json.containsKey('id')) {
      return null;
    }

    final nominationsRaw = json['nominations'];
    final myVotesRaw = json['my_votes'];

    final nominationsJson = (nominationsRaw as Map?)?.cast<String, dynamic>() ?? {};
    final myVotesJson = <String, String>{};
    if (myVotesRaw is Map) {
      myVotesRaw.forEach((k, v) {
        myVotesJson[k.toString()] = v.toString();
      });
    }

    final nominations = <String, List<ElectionNomineeEntity>>{};
    nominationsJson.forEach((role, nominees) {
      if (nominees is List) {
        nominations[role] = nominees
            .map((n) => ElectionNomineeEntity(
                  nomineeId: n['nominee_id'].toString(),
                  nomineeName: n['nominee_name'] as String,
                  nominationCount: parseInt(n['nomination_count']),
                ))
            .toList();
      }
    });

    return ElectionEntity(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      nominations: nominations,
      myVotes: myVotesJson,
    );
  }
}

class GroupSlotModel {
  static GroupSlotEntity fromJson(Map<String, dynamic> json) {
    return GroupSlotEntity(
      membershipId: json['membership_id'].toString(),
      slotName: json['slot_name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      rotationPosition: json['rotation_position'] != null
          ? parseInt(json['rotation_position'])
          : null,
      isCurrentBeneficiary: json['is_current_beneficiary'] as bool? ?? false,
      joinedAt: parseDateTime(json['joined_at']) ?? DateTime.now(),
    );
  }
}

class UserSearchResultModel {
  static UserSearchResultEntity fromJson(Map<String, dynamic> json) {
    return UserSearchResultEntity(
      id: json['id'].toString(),
      username: json['username'] as String,
      name: json['name'] as String,
    );
  }
}
