import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../providers/providers.dart';

class GroupDetailsScreen extends ConsumerWidget {
  const GroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          final group = groups.firstWhere((g) => g.id == groupId);
          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                _GroupHeader(group: group),
                const TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.mediumGray,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Members'),
                    Tab(text: 'Ledger'),
                    Tab(text: 'Loans'),
                    Tab(text: 'Chat'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(group: group),
                      _MembersTab(group: group),
                      const Center(child: Text('Ledger coming soon')),
                      const Center(child: Text('Group loans coming soon')),
                      const Center(child: Text('Group chat coming soon')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(
                label: 'Members',
                value: '${group.memberCount}/${group.maxMembers}',
              ),
              _HeaderStat(
                label: 'Balance',
                value: Formatters.currency(group.fundBalance),
              ),
              _HeaderStat(
                label: 'MRI Avg',
                value: Formatters.mriScore(group.averageMri),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('Contribution', Formatters.currency(group.contributionAmount)),
        _InfoRow('Frequency', group.frequency),
        _InfoRow('Start Date', Formatters.date(group.startDate)),
        _InfoRow('Cycle Progress', '${group.cycleProgress}/${group.maxMembers}'),
        if (group.invitationCode != null)
          _InfoRow('Invite Code', group.invitationCode!),
        if (group.rules != null) ...[
          const SizedBox(height: 16),
          Text('Rules', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(group.rules!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: group.members.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final member = group.members[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: member.isCurrentBeneficiary
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
            child: Text(member.name[0]),
          ),
          title: Row(
            children: [
              Text(member.name),
              if (member.isCurrentBeneficiary) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Beneficiary',
                    style: TextStyle(fontSize: 10, color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(_roleLabel(member.role)),
          trailing: Text(
            'MRI ${Formatters.mriScore(member.mriScore)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
        );
      },
    );
  }

  String _roleLabel(GroupRole role) {
    switch (role) {
      case GroupRole.president:
        return 'President';
      case GroupRole.treasurer:
        return 'Treasurer';
      case GroupRole.member:
        return 'Member';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
