import 'package:equatable/equatable.dart';

class BalanceUpdateEntity extends Equatable {
  const BalanceUpdateEntity({
    this.walletBalance,
    this.savingsBalance,
  });

  final double? walletBalance;
  final double? savingsBalance;

  @override
  List<Object?> get props => [walletBalance, savingsBalance];
}
