import 'package:equatable/equatable.dart';
import 'transaction_entity.dart';

class MriBreakdownEntity extends Equatable {
  const MriBreakdownEntity({
    required this.paymentPunctuality,
    required this.attendance,
    required this.loanRepayment,
    required this.contributionConsistency,
    required this.communityParticipation,
  });

  final double paymentPunctuality;
  final double attendance;
  final double loanRepayment;
  final double contributionConsistency;
  final double communityParticipation;

  double get overall =>
      (paymentPunctuality +
              attendance +
              loanRepayment +
              contributionConsistency +
              communityParticipation) /
          5;

  @override
  List<Object?> get props => [
        paymentPunctuality,
        attendance,
        loanRepayment,
        contributionConsistency,
        communityParticipation,
      ];
}

class DashboardEntity extends Equatable {
  const DashboardEntity({
    required this.njangiBalance,
    required this.totalContributions,
    required this.nextPaymentDate,
    required this.activeGroups,
    required this.pendingPayments,
    required this.totalSavings,
    required this.activeLoansAmount,
    required this.socialFundBalance,
    required this.currentPayout,
    required this.mriScore,
    required this.mriTrend,
    required this.recentActivity,
    this.mriBreakdown,
    this.walletBalance = 0,
    this.savingsBalance = 0,
    this.totalBalance = 0,
  });

  final double njangiBalance;
  final double totalContributions;
  final DateTime nextPaymentDate;
  final int activeGroups;
  final int pendingPayments;
  final double totalSavings;
  final double activeLoansAmount;
  final double socialFundBalance;
  final double currentPayout;
  final double mriScore;
  final double mriTrend;
  final List<TransactionEntity> recentActivity;
  final MriBreakdownEntity? mriBreakdown;
  final double walletBalance;
  final double savingsBalance;
  final double totalBalance;

  @override
  List<Object?> get props => [
        njangiBalance,
        totalContributions,
        nextPaymentDate,
        activeGroups,
        pendingPayments,
        totalSavings,
        activeLoansAmount,
        socialFundBalance,
        currentPayout,
        mriScore,
        mriTrend,
        recentActivity,
        mriBreakdown,
        walletBalance,
        savingsBalance,
        totalBalance,
      ];
}
