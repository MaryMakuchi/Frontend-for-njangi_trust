import '../../core/utils/api_helper.dart';
import '../../domain/entities/contribution_entity.dart';

class ContributionModel {
  static ContributionEntity fromJson(Map<String, dynamic> json) {
    return ContributionEntity(
      id: json['id'].toString(),
      groupId: json['group_id'].toString(),
      groupName: json['group_name'] as String? ?? '',
      amount: parseDouble(json['amount']),
      dueDate: parseDate(json['due_date']),
      status: _parseStatus(json['status'] as String?),
      paidDate: parseDateTime(json['paid_date']),
      paymentMethod: json['payment_method'] as String?,
    );
  }

  static ContributionStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return ContributionStatus.completed;
      case 'late':
        return ContributionStatus.late;
      case 'pending':
        return ContributionStatus.pending;
      default:
        return ContributionStatus.outstanding;
    }
  }
}
