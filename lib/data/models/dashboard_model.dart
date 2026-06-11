import '../../core/utils/api_helper.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'transaction_model.dart';

class DashboardModel {
  static DashboardEntity fromJson(Map<String, dynamic> json) {
    final breakdown = json['mri_breakdown'] as Map<String, dynamic>?;
    final activity = json['recent_activity'] as List? ?? [];

    return DashboardEntity(
      njangiBalance: parseDouble(json['njangi_balance']),
      totalContributions: parseDouble(json['total_contributions']),
      nextPaymentDate: parseDate(json['next_payment_date']),
      activeGroups: parseInt(json['active_groups']),
      pendingPayments: parseInt(json['pending_payments']),
      totalSavings: parseDouble(json['total_savings']),
      activeLoansAmount: parseDouble(json['active_loans_amount']),
      socialFundBalance: parseDouble(json['social_fund_balance']),
      currentPayout: parseDouble(json['current_payout']),
      mriScore: parseDouble(json['mri_score']),
      mriTrend: parseDouble(json['mri_trend']),
      mriBreakdown: breakdown != null
          ? MriBreakdownEntity(
              paymentPunctuality: parseDouble(breakdown['payment_punctuality']),
              attendance: parseDouble(breakdown['attendance']),
              loanRepayment: parseDouble(breakdown['loan_repayment']),
              contributionConsistency: parseDouble(breakdown['contribution_consistency']),
              communityParticipation: parseDouble(breakdown['community_participation']),
            )
          : null,
      recentActivity: activity
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      walletBalance: parseDouble(json['wallet_balance']),
      savingsBalance: parseDouble(json['savings_balance']),
      totalBalance: parseDouble(json['total_balance']),
    );
  }
}
