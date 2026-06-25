import 'package:equatable/equatable.dart';

enum TransactionType {
  contribution,
  payout,
  loanDisbursement,
  loanRepayment,
  socialFund,
  walletTopup,
  walletWithdrawal,
  savingsDeposit,
  savingsWithdrawal,
}

enum TransactionStatus { pending, completed, failed, verified }

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.groupName,
    this.hash,
    this.isCredit = false,
    this.onChain = false,
    this.explorerUrl,
    this.initiatedBy,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime date;
  final String? groupName;
  final String? hash;
  final bool isCredit;
  final bool onChain;
  final String? explorerUrl;
  final String? initiatedBy;

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        type,
        status,
        date,
        groupName,
        hash,
        isCredit,
        onChain,
        explorerUrl,
        initiatedBy,
      ];
}
