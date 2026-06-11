import '../../core/utils/api_helper.dart';
import '../../domain/entities/group_message_entity.dart';

class GroupMessageModel {
  static GroupMessageEntity fromJson(Map<String, dynamic> json) {
    return GroupMessageEntity(
      id: json['id'].toString(),
      groupId: json['group_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }
}
