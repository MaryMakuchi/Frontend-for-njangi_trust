import 'package:equatable/equatable.dart';

class SavingsPeriodEntity extends Equatable {
  const SavingsPeriodEntity({
    required this.id,
    required this.interestRate,
    required this.interestType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isClosed,
  });

  final String id;
  final double interestRate;
  final String interestType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isClosed;

  @override
  List<Object?> get props => [
        id,
        interestRate,
        interestType,
        startDate,
        endDate,
        status,
        isClosed,
      ];
}

class SavingsDepositEntity extends Equatable {
  const SavingsDepositEntity({
    required this.amount,
    required this.date,
  });

  final double amount;
  final DateTime date;

  @override
  List<Object?> get props => [amount, date];
}

class SavingsSummaryEntity extends Equatable {
  const SavingsSummaryEntity({
    required this.principal,
    required this.interestAccrued,
    required this.total,
    this.deposits = const [],
  });

  final double principal;
  final double interestAccrued;
  final double total;
  final List<SavingsDepositEntity> deposits;

  @override
  List<Object?> get props => [principal, interestAccrued, total, deposits];
}

class GroupSavingsEntity extends Equatable {
  const GroupSavingsEntity({
    this.period,
    this.mySavings,
  });

  final SavingsPeriodEntity? period;
  final SavingsSummaryEntity? mySavings;

  @override
  List<Object?> get props => [period, mySavings];
}

class SavingsWithdrawalResultEntity extends Equatable {
  const SavingsWithdrawalResultEntity({
    required this.amountWithdrawn,
    required this.newWalletBalance,
  });

  final double amountWithdrawn;
  final double newWalletBalance;

  @override
  List<Object?> get props => [amountWithdrawn, newWalletBalance];
}
