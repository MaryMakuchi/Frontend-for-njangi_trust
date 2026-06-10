import '../../core/utils/api_helper.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  static TransactionEntity fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'].toString(),
      title: json['title'] as String,
      amount: parseDouble(json['amount']),
      type: _parseType(json['type'] as String?),
      status: _parseStatus(json['status'] as String?),
      date: parseDateTime(json['date']) ?? DateTime.now(),
      groupName: json['group_name'] as String?,
      hash: json['hash'] as String?,
      isCredit: json['is_credit'] as bool? ?? false,
    );
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'contribution':
        return TransactionType.contribution;
      case 'payout':
        return TransactionType.payout;
      case 'loan_disbursement':
        return TransactionType.loanDisbursement;
      case 'loan_repayment':
        return TransactionType.loanRepayment;
      case 'social_fund':
        return TransactionType.socialFund;
      default:
        return TransactionType.contribution;
    }
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'verified':
        return TransactionStatus.verified;
      case 'failed':
        return TransactionStatus.failed;
      case 'pending':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.completed;
    }
  }
}
