import 'package:equatable/equatable.dart';

enum LoanStatus { pending, approved, rejected, active, repaid }

class LoanEntity extends Equatable {
  const LoanEntity({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.durationMonths,
    required this.status,
    required this.interestRate,
    this.remainingBalance,
    this.dueDate,
    this.groupId,
    this.groupName,
    this.approvedDate,
  });

  final String id;
  final double amount;
  final String purpose;
  final int durationMonths;
  final LoanStatus status;
  final double interestRate;
  final double? remainingBalance;
  final DateTime? dueDate;
  final String? groupId;
  final String? groupName;
  final DateTime? approvedDate;

  double get totalRepayment =>
      amount + (amount * interestRate / 100 * durationMonths / 12);

  @override
  List<Object?> get props => [
        id,
        amount,
        purpose,
        durationMonths,
        status,
        interestRate,
        remainingBalance,
        dueDate,
        groupId,
        groupName,
        approvedDate,
      ];
}

enum LoanVoteDecision { approve, reject }

class PendingLoanVoteEntity extends Equatable {
  const PendingLoanVoteEntity({
    required this.loanId,
    required this.requesterName,
    required this.groupName,
    required this.amount,
    required this.purpose,
    required this.durationMonths,
    required this.approveCount,
    required this.rejectCount,
    required this.eligibleVoters,
    required this.majorityThreshold,
    this.yourVote,
  });

  final String loanId;
  final String requesterName;
  final String groupName;
  final double amount;
  final String purpose;
  final int durationMonths;
  final int approveCount;
  final int rejectCount;
  final int eligibleVoters;
  final int majorityThreshold;
  final LoanVoteDecision? yourVote;

  @override
  List<Object?> get props => [
        loanId,
        requesterName,
        groupName,
        amount,
        purpose,
        durationMonths,
        approveCount,
        rejectCount,
        eligibleVoters,
        majorityThreshold,
        yourVote,
      ];
}

class LoanVoteResultEntity extends Equatable {
  const LoanVoteResultEntity({
    required this.loanStatus,
    required this.approveCount,
    required this.rejectCount,
    required this.eligibleVoters,
    required this.majorityThreshold,
    required this.yourVote,
  });

  final LoanStatus loanStatus;
  final int approveCount;
  final int rejectCount;
  final int eligibleVoters;
  final int majorityThreshold;
  final LoanVoteDecision yourVote;

  @override
  List<Object?> get props => [
        loanStatus,
        approveCount,
        rejectCount,
        eligibleVoters,
        majorityThreshold,
        yourVote,
      ];
}
