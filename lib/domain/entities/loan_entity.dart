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
