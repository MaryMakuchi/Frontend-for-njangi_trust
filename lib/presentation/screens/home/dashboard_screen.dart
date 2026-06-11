import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/balance_text.dart';
import '../../widgets/financial_summary_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/mri_score_card.dart';
import '../../widgets/quick_action_chip.dart';
import '../../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (dashboard) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (user?.fullName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.hello}, ${user?.fullName ?? 'Member'}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Trusted Member',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: MriScoreCard(
                            score: dashboard.mriScore,
                            trend: dashboard.mriTrend,
                            compact: true,
                            onTap: () => context.push(AppRoutes.mriScore),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _TotalBalanceCard(
                            totalBalance: dashboard.totalBalance,
                            onTap: () => context.push(AppRoutes.savings),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 118,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FinancialSummaryCard(
                          label: AppStrings.totalSavings,
                          value: Formatters.currency(dashboard.totalSavings),
                          amount: dashboard.totalSavings,
                          icon: Icons.savings_outlined,
                          iconColor: AppColors.indigo,
                          onTap: () => context.push(AppRoutes.savings),
                        ),
                        const SizedBox(width: 12),
                        FinancialSummaryCard(
                          label: AppStrings.activeLoans,
                          value: Formatters.currency(dashboard.activeLoansAmount),
                          amount: dashboard.activeLoansAmount,
                          icon: Icons.account_balance_outlined,
                          iconColor: AppColors.violet,
                          onTap: () => context.go(AppRoutes.loans),
                        ),
                        const SizedBox(width: 12),
                        FinancialSummaryCard(
                          label: AppStrings.socialFund,
                          value: Formatters.currency(dashboard.socialFundBalance),
                          amount: dashboard.socialFundBalance,
                          icon: Icons.favorite_outline,
                          iconColor: AppColors.orchid,
                          onTap: () => context.push(AppRoutes.socialFund),
                        ),
                        const SizedBox(width: 12),
                        _CurrentPayoutCard(
                          label: AppStrings.currentPayout,
                          amount: dashboard.currentPayout,
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.secondary,
                          onWalletTap: () => context.push(AppRoutes.walletAccounts),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.purpleSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, color: AppColors.purple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.nextPayout,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    Formatters.date(dashboard.nextPaymentDate),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.purple,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            BalanceText(
                              dashboard.currentPayout,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                              iconColor: AppColors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      QuickActionChip(
                        label: 'Pay',
                        icon: Icons.payment,
                        onTap: () => context.push('${AppRoutes.contributions}/pay'),
                      ),
                      QuickActionChip(
                        label: 'Join Group',
                        icon: Icons.group_add,
                        color: AppColors.purple,
                        onTap: () => context.push('${AppRoutes.groups}/join'),
                      ),
                      QuickActionChip(
                        label: 'Create Group',
                        icon: Icons.add_circle_outline,
                        color: AppColors.accent,
                        onTap: () => context.push('${AppRoutes.groups}/create'),
                      ),
                      QuickActionChip(
                        label: 'Request Loan',
                        icon: Icons.request_quote,
                        color: AppColors.info,
                        onTap: () => context.push('${AppRoutes.loans}/request'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.recentActivity,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.blockchainLedger),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  ...dashboard.recentActivity.map(
                    (t) => TransactionTile(transaction: t),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentPayoutCard extends StatelessWidget {
  const _CurrentPayoutCard({
    required this.label,
    required this.amount,
    required this.icon,
    this.iconColor,
    this.onWalletTap,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onWalletTap;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;

    return Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 11,
                    height: 1.1,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: BalanceText(
                      amount,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.1,
                            color: AppColors.darkGray,
                          ),
                      iconColor: AppColors.mediumGray,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onWalletTap,
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance, this.onTap});

  final double totalBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            BalanceText(
              totalBalance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
              iconColor: AppColors.white,
            ),
            const SizedBox(height: 4),
            Text(
              'Savings + Wallet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
