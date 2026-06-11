import '../../core/utils/api_helper.dart';
import '../../domain/entities/loan_entity.dart';

class LoanModel {
  static LoanEntity fromJson(Map<String, dynamic> json) {
    return LoanEntity(
      id: json['id'].toString(),
      amount: parseDouble(json['amount']),
      purpose: json['purpose'] as String,
      durationMonths: parseInt(json['duration_months']),
      status: _parseStatus(json['status'] as String?),
      interestRate: parseDouble(json['interest_rate']),
      remainingBalance: json['remaining_balance'] != null
          ? parseDouble(json['remaining_balance'])
          : null,
      dueDate: parseDateTime(json['due_date']),
      groupId: json['group_id']?.toString(),
      groupName: json['group_name'] as String?,
      approvedDate: parseDateTime(json['approved_date']),
    );
  }

  static LoanStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return LoanStatus.approved;
      case 'rejected':
        return LoanStatus.rejected;
      case 'active':
        return LoanStatus.active;
      case 'repaid':
        return LoanStatus.repaid;
      default:
        return LoanStatus.pending;
    }
  }
}
