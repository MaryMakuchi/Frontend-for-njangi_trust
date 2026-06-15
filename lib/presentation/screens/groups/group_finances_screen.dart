import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/reconciliation_entity.dart';
import '../../providers/providers.dart';

/// Treasurer-liability reconciliation dashboard for a group.
///
/// Shows, for the current cycle, what *should* have been collected vs. what
/// actually came in, and names exactly which members are still behind — so any
/// shortfall is traceable to specific late payers rather than suspicion falling
/// on whoever holds the money.
class GroupFinancesScreen extends ConsumerWidget {
  const GroupFinancesScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconAsync = ref.watch(reconciliationProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Group Finances')),
      body: reconAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load finances: $e'),
          ),
        ),
        data: (r) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reconciliationProvider(groupId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBanner(recon: r),
              const SizedBox(height: 16),
              _CycleCard(recon: r),
              const SizedBox(height: 16),
              _LifetimeCard(recon: r),
              const SizedBox(height: 16),
              _MembersSection(recon: r),
              const SizedBox(height: 24),
              Text(
                'Every figure here is computed from the group\'s recorded '
                'transactions. Nobody can quietly edit the books — the numbers '
                'always trace back to who paid and who was paid.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGray,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.recon});

  final ReconciliationEntity recon;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String message;

    final unpaidCount = recon.unpaidMembers.length;
    switch (recon.status) {
      case 'surplus':
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.trending_up;
        message =
            'Surplus of ${Formatters.currency(recon.collected - recon.expected)} '
            'collected this cycle.';
        break;
      case 'on_track':
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.check_circle;
        message = 'On track — every member has paid this cycle.';
        break;
      default:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.warning_amber_rounded;
        message =
            'Shortfall of ${Formatters.currency(recon.outstanding)} — '
            '$unpaidCount member${unpaidCount == 1 ? '' : 's'} '
            'still ${unpaidCount == 1 ? 'has' : 'have'} not paid.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.recon});

  final ReconciliationEntity recon;

  @override
  Widget build(BuildContext context) {
    final progress =
        recon.expected <= 0 ? 0.0 : (recon.collected / recon.expected).clamp(0.0, 1.0);
    return _Card(
      title: 'This Cycle',
      child: Column(
        children: [
          _MoneyRow(
            'Expected',
            recon.expected,
            subtitle:
                '${recon.activeMembers} members × ${Formatters.currency(recon.contributionAmount)}',
          ),
          _MoneyRow('Collected', recon.collected,
              subtitle: '${recon.paidCount} paid so far'),
          _MoneyRow(
            'Outstanding',
            recon.outstanding,
            valueColor:
                recon.outstanding > 0 ? AppColors.error : AppColors.success,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({required this.recon});

  final ReconciliationEntity recon;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Running Totals',
      child: Column(
        children: [
          _MoneyRow('Current fund balance', recon.fundBalance),
          _MoneyRow('Total ever collected', recon.totalCollected),
          _MoneyRow('Total ever paid out', recon.totalPaidOut),
          _MoneyRow('Loans outstanding', recon.loansOutstanding),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.recon});

  final ReconciliationEntity recon;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Member Payment Status',
      child: Column(
        children: [
          for (final m in recon.members) _MemberTile(member: m),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final ReconMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final paid = member.hasPaid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: paid ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (member.role != 'member')
                  Text(
                    member.role[0].toUpperCase() + member.role.substring(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            paid ? 'Paid' : 'Pending',
            style: TextStyle(
              color: paid ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount,
      {this.subtitle, this.valueColor});

  final String label;
  final double amount;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGray,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
