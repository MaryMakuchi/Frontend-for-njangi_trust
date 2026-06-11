import '../../core/utils/api_helper.dart';
import '../../domain/entities/loan_entity.dart';

class LoanModel {
  static LoanEntity fromJson(Map<String, dynamic> json) {
    return LoanEntity(
      id: json['id'].toString(),
      amount: parseDouble(json['amount']),
      purpose: json['purpose'] as String,
      durationMonths: parseInt(json['duration_months']),
      status: parseStatus(json['status'] as String?),
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

  static LoanStatus parseStatus(String? status) {
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

class PendingLoanVoteModel {
  static PendingLoanVoteEntity fromJson(Map<String, dynamic> json) {
    return PendingLoanVoteEntity(
      loanId: json['loan_id'].toString(),
      requesterName: json['requester_name'] as String,
      groupName: json['group_name'] as String,
      amount: parseDouble(json['amount']),
      purpose: json['purpose'] as String,
      durationMonths: parseInt(json['duration_months']),
      approveCount: parseInt(json['approve_count']),
      rejectCount: parseInt(json['reject_count']),
      eligibleVoters: parseInt(json['eligible_voters']),
      majorityThreshold: parseInt(json['majority_threshold']),
      yourVote: _parseDecision(json['your_vote'] as String?),
    );
  }

  static LoanVoteDecision? _parseDecision(String? decision) {
    switch (decision) {
      case 'approve':
        return LoanVoteDecision.approve;
      case 'reject':
        return LoanVoteDecision.reject;
      default:
        return null;
    }
  }
}

class LoanVoteResultModel {
  static LoanVoteResultEntity fromJson(Map<String, dynamic> json) {
    return LoanVoteResultEntity(
      loanStatus: LoanModel.parseStatus(json['loan_status'] as String?),
      approveCount: parseInt(json['approve_count']),
      rejectCount: parseInt(json['reject_count']),
      eligibleVoters: parseInt(json['eligible_voters']),
      majorityThreshold: parseInt(json['majority_threshold']),
      yourVote: PendingLoanVoteModel._parseDecision(json['your_vote'] as String?) ??
          LoanVoteDecision.approve,
    );
  }
}
