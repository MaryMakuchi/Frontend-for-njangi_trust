import '../../core/utils/api_helper.dart';
import '../../domain/entities/due_date_entity.dart';

class DueDateModel {
  static DueDateEntity fromJson(Map<String, dynamic> json) {
    return DueDateEntity(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name'] as String?,
      amount: json['amount'] != null ? parseDouble(json['amount']) : null,
      dueDatetime: parseDateTime(json['due_datetime']) ?? DateTime.now(),
    );
  }
}
