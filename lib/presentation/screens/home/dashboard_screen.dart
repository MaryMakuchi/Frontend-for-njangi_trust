import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/njangi_hype.dart';
import '../../../domain/entities/due_date_entity.dart';
import '../../../domain/entities/group_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/balance_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/financial_summary_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/mri_score_card.dart';
import '../../widgets/quick_action_chip.dart';
import '../../widgets/transaction_tile.dart';
import 'due_dates_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlayNjangiGroupsSheet(context, ref),
        icon: const Icon(Icons.casino_outlined),
        label: const Text('Play Njangi'),
      ),
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
                        onPressed: () => context
                            .push(AppRoutes.notifications)
                            .then((_) => ref
                                .invalidate(unreadNotificationCountProvider)),
                        icon: Builder(
                          builder: (_) {
                            final count = ref
                                    .watch(unreadNotificationCountProvider)
                                    .valueOrNull ??
                                0;
                            if (count == 0) {
                              return const Icon(Icons.notifications_outlined);
                            }
                            return Badge(
                              label: Text(count > 99 ? '99+' : '$count'),
                              child: const Icon(Icons.notifications_outlined),
                            );
                          },
                        ),
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
                          child: _TotalBalanceCard(
                            totalBalance: dashboard.totalBalance,
                            onTap: () => context.push(AppRoutes.savings),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: MriScoreCard(
                            score: dashboard.mriScore,
                            trend: dashboard.mriTrend,
                            compact: true,
                            onTap: () => context.push(AppRoutes.mriScore),
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
                        ),
                        const SizedBox(width: 12),
                        FinancialSummaryCard(
                          label: 'Wallet',
                          value: Formatters.currency(dashboard.walletBalance),
                          amount: dashboard.walletBalance,
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.primary,
                          onTap: () => context.push(AppRoutes.walletAccounts),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _UpcomingDueDatesSection(),
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

  void _showPlayNjangiGroupsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _PlayNjangiGroupsSheet(),
    );
  }
}

class _UpcomingDueDatesSection extends ConsumerWidget {
  const _UpcomingDueDatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(dueDatesProvider('3m'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Due Dates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.dueDates),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        duesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Error: $e',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          data: (dues) {
            if (dues.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No upcoming dues 🎉'),
              );
            }
            final sorted = [...dues]
              ..sort((a, b) => a.dueDatetime.compareTo(b.dueDatetime));
            final top = sorted.take(2).toList();
            return Column(
              children: [
                for (var i = 0; i < top.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  DueDateTile(due: top[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PlayNjangiGroupsSheet extends ConsumerWidget {
  const _PlayNjangiGroupsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Play Njangi', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select a group with an active picking order',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          groupsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Error: $e'),
            ),
            data: (groups) {
              final eligible = groups.where((g) => g.scheduleGenerated).toList();
              if (eligible.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No groups have an active picking order yet'),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eligible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = eligible[index];
                  return _PlayNjangiGroupTile(group: group);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayNjangiGroupTile extends StatelessWidget {
  const _PlayNjangiGroupTile({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    final pickerName = group.currentPicker?.name;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).pop();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _PlayNjangiConfirmSheet(group: group),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.purpleSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (pickerName != null)
                    Text(
                      'Currently picking: $pickerName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mediumGray),
          ],
        ),
      ),
    );
  }
}

class _PlayNjangiConfirmSheet extends ConsumerStatefulWidget {
  const _PlayNjangiConfirmSheet({required this.group});

  final GroupEntity group;

  @override
  ConsumerState<_PlayNjangiConfirmSheet> createState() => _PlayNjangiConfirmSheetState();
}

class _PlayNjangiConfirmSheetState extends ConsumerState<_PlayNjangiConfirmSheet> {
  bool _isLoading = false;

  // Display label -> source value passed to playNjangi.
  static const Map<String, String> _sources = {
    'Wallet': 'wallet',
    'MoMo': 'momo',
    'Bank': 'bank',
  };
  String _source = 'wallet';

  Future<void> _confirmAndPlay() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(groupRepositoryProvider)
          .playNjangi(widget.group.id, source: _source);
      ref.invalidate(groupsProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      Navigator.of(context).pop();

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Payment of ${Formatters.currency(result.amount)} successful!')),
      );

      if (result.cycleCompleted && result.payout != null) {
        final payout = result.payout!;
        final pickerName = result.currentPicker?.name;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cycle Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.currency(payout.amount)} has been paid out to ${payout.recipientName}.',
                ),
                if (pickerName != null) ...[
                  const SizedBox(height: 8),
                  Text('The new current picker is $pickerName.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final currentPicker = group.currentPicker;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final isMyTurn = currentPicker != null &&
        currentUserId != null &&
        currentPicker.id == currentUserId;
    final nextDue = group.nextPlayDue;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Play Njangi', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.name,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to pay',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                BalanceText(
                  group.contributionAmount,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  iconColor: AppColors.darkGray,
                ),
                const SizedBox(height: 4),
                Text(
                  'This is your fixed group contribution and cannot be changed.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.mediumGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextDue != null
                      ? 'Due: ${formatDueDateTime(nextDue)} (${relativeDueLabel(nextDue)})'
                      : 'No schedule set',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMyTurn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: AppColors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      njangiHypeMessage(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentPicker != null
                          ? 'Currently picking: ${currentPicker.name}'
                          : 'Picking order not yet assigned',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Payment source',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final entry in _sources.entries)
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(entry.key,
                        style: Theme.of(context).textTheme.bodySmall),
                    value: entry.value,
                    groupValue: _source,
                    onChanged: (v) => setState(() => _source = v!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Confirm & Play',
            icon: Icons.check_circle_outline,
            isLoading: _isLoading,
            onPressed: _confirmAndPlay,
          ),
        ],
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
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color? iconColor;

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
            FittedBox(
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: BalanceText(
                totalBalance,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                iconColor: AppColors.white,
              ),
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
