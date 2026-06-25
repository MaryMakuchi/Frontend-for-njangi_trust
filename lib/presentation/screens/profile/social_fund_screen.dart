import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/social_fund_entity.dart';
import '../../providers/providers.dart';

class SocialFundScreen extends ConsumerWidget {
  const SocialFundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Social Fund')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(groupsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            dashboardAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (dashboard) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    const Text('Total Social Fund Balance'),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(dashboard.socialFundBalance),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('By Group', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Join or create a group to see its social fund.'),
                  );
                }
                return Column(
                  children: groups.map((g) => _GroupSocialFundCard(group: g)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSocialFundCard extends ConsumerWidget {
  const _GroupSocialFundCard({required this.group});

  final GroupEntity group;

  bool _isPresident(WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return false;
    final membership = group.members.where((m) => m.id == user.id);
    return membership.isNotEmpty && membership.first.role == GroupRole.president;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(groupSocialFundsProvider(group.id));
    final isPresident = _isPresident(ref);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group.name, style: Theme.of(context).textTheme.titleSmall),
              TextButton(
                onPressed: () => context.push('/groups/${group.id}'),
                child: const Text('View Group'),
              ),
            ],
          ),
          fundsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (funds) {
              if (funds.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isPresident
                        ? 'No social fund yet. Create one from the group page.'
                        : 'No social fund has been created for this group yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: funds.map((fund) => _FundSummary(fund: fund)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FundSummary extends StatelessWidget {
  const _FundSummary({required this.fund});

  final SocialFundEntity fund;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fund.reason, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${Formatters.date(fund.startDate)} - ${Formatters.date(fund.endDate)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(fund.balance),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (fund.contributions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${fund.contributions.length} contribution(s) so far',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }
}
