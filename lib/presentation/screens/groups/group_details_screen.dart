import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/social_fund_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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
            length: 6,
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
                    Tab(text: 'Social Fund'),
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
                      _SocialFundTab(group: group),
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

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.group});

  final GroupEntity group;

  GroupRole? _myRole(WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return null;
    final membership = group.members.where((m) => m.id == user.id);
    return membership.isEmpty ? null : membership.first.role;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresident = _myRole(ref) == GroupRole.president;
    final isFull = group.memberCount >= group.maxMembers;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('Contribution', Formatters.currency(group.contributionAmount)),
        _InfoRow('Frequency', group.frequency),
        _InfoRow('Start Date', Formatters.date(group.startDate)),
        _InfoRow('Duration', '${group.durationMonths} months'),
        _InfoRow('Exhaustion Date', Formatters.date(group.effectiveEndDate)),
        if (group.targetAmount != null)
          _InfoRow('Target Picking Amount', Formatters.currency(group.targetAmount!)),
        _InfoRow('Pickers per Cycle', '${group.pickersPerCycle}'),
        _InfoRow('Cycle Progress', '${group.cycleProgress}/${group.maxMembers}'),
        if (group.invitationCode != null)
          _InfoRow('Invite Code', group.invitationCode!),
        if (group.rules != null) ...[
          const SizedBox(height: 16),
          Text('Rules', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(group.rules!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (isPresident) ...[
          const SizedBox(height: 24),
          Text('Picking Order', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (group.scheduleGenerated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('The picking order has been assigned.'),
            )
          else if (!isFull)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'The picking order can be assigned once the group is full.',
              ),
            )
          else
            _PickingOrderActions(group: group),
        ],
      ],
    );
  }
}

class _PickingOrderActions extends ConsumerStatefulWidget {
  const _PickingOrderActions({required this.group});

  final GroupEntity group;

  @override
  ConsumerState<_PickingOrderActions> createState() => _PickingOrderActionsState();
}

class _PickingOrderActionsState extends ConsumerState<_PickingOrderActions> {
  bool _isLoading = false;
  late List<GroupMemberEntity> _order;

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.group.members);
  }

  Future<void> _assign(String mode, [List<String>? order]) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).assignPickingOrder(
            groupId: widget.group.id,
            mode: mode,
            order: order,
          );
      ref.invalidate(groupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picking order assigned!')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          label: 'Randomly Assign Picking Order',
          icon: Icons.shuffle,
          isLoading: _isLoading,
          onPressed: () => _assign('random'),
        ),
        const SizedBox(height: 12),
        Text(
          'Manual Order',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Drag members to set the picking order, then confirm below.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
          },
          children: [
            for (var i = 0; i < _order.length; i++)
              ListTile(
                key: ValueKey(_order[i].id),
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_order[i].name),
                trailing: const Icon(Icons.drag_handle),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Confirm Manual Order',
          isOutlined: true,
          isLoading: _isLoading,
          onPressed: () => _assign('manual', _order.map((m) => m.id).toList()),
        ),
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
          subtitle: Text(
            member.pickCycle != null
                ? '${_roleLabel(member.role)} · Picks in cycle ${member.pickCycle}'
                : _roleLabel(member.role),
          ),
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

class _SocialFundTab extends ConsumerWidget {
  const _SocialFundTab({required this.group});

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

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupSocialFundsProvider(group.id)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isPresident)
            CustomButton(
              label: 'Create Social Fund',
              icon: Icons.add,
              onPressed: () => _showCreateFundDialog(context, ref),
            ),
          const SizedBox(height: 16),
          fundsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (funds) {
              if (funds.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No social funds for this group yet.')),
                );
              }
              return Column(
                children: funds
                    .map((fund) => _SocialFundCard(group: group, fund: fund))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateFundDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    final targetController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Create Social Fund'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Reason',
                  controller: reasonController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Target Amount (CFA, optional)',
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(Formatters.date(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text(Formatters.date(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 1095)),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(groupRepositoryProvider).createSocialFund(
                              groupId: group.id,
                              reason: reasonController.text.trim(),
                              startDate: startDate,
                              endDate: endDate,
                              targetAmount: targetController.text.trim().isEmpty
                                  ? null
                                  : double.parse(
                                      targetController.text.replaceAll(',', '')),
                            );
                        ref.invalidate(groupSocialFundsProvider(group.id));
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message =
                              e is ApiException ? e.message : AppStrings.genericError;
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialFundCard extends ConsumerStatefulWidget {
  const _SocialFundCard({required this.group, required this.fund});

  final GroupEntity group;
  final SocialFundEntity fund;

  @override
  ConsumerState<_SocialFundCard> createState() => _SocialFundCardState();
}

class _SocialFundCardState extends ConsumerState<_SocialFundCard> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _contribute() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).contributeSocialFund(
            groupId: widget.group.id,
            fundId: widget.fund.id,
            amount: amount,
          );
      ref.invalidate(groupSocialFundsProvider(widget.group.id));
      ref.invalidate(dashboardProvider);
      ref.read(authStateProvider.notifier).refreshUser();
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution successful!')),
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
    final fund = widget.fund;
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
          Text(fund.reason, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '${Formatters.date(fund.startDate)} - ${Formatters.date(fund.endDate)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(fund.balance),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (fund.targetAmount != null)
            Text(
              'Target: ${Formatters.currency(fund.targetAmount!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Amount (CFA)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _contribute,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Contribute'),
                  ),
                ),
              ),
            ],
          ),
          if (fund.contributions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Contributions', style: Theme.of(context).textTheme.titleSmall),
            ...fund.contributions.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.userName),
                subtitle: Text(Formatters.date(c.createdAt)),
                trailing: Text(Formatters.currency(c.amount)),
              ),
            ),
          ],
        ],
      ),
    );
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
