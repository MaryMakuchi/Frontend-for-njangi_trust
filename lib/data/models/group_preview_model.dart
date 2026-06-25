import '../../core/utils/api_helper.dart';
import '../../domain/entities/group_preview_entity.dart';

class GroupPreviewModel {
  static GroupPreviewEntity fromJson(Map<String, dynamic> json) {
    return GroupPreviewEntity(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      rules: json['rules'] as String?,
      contributionAmount: parseDouble(json['contribution_amount']),
      maxMembers: parseInt(json['max_members']),
      memberCount: parseInt(json['member_count']),
      playFrequency: json['play_frequency'] as String?,
      nextPlayDue: parseDateTime(json['next_play_due']),
      presidentName: json['president_name'] as String?,
      isMember: json['is_member'] as bool? ?? false,
      hasPendingRequest: json['has_pending_request'] as bool? ?? false,
    );
  }
}
