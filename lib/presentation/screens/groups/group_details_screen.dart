import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/membership_request_entity.dart';
import '../../../domain/entities/social_fund_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/balance_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/group_savings_panel.dart';

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
            length: 7,
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
                    Tab(text: 'Savings'),
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
                      _SavingsTab(group: group),
                      const Center(child: Text('Group loans coming soon')),
                      _ChatTab(group: group),
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
                amount: group.fundBalance,
              ),
              _HeaderStat(
                label: 'MRI Avg',
                value: Formatters.mriScore(group.averageMri),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.currentPicker != null
                        ? 'Currently picking: ${group.currentPicker!.name}'
                        : 'Picking order not yet assigned',
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPlayNjangiSheet(context, group),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.white.withValues(alpha: 0.12),
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white),
              ),
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Play Njangi'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayNjangiSheet(BuildContext context, GroupEntity group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlayNjangiSheet(group: group),
    );
  }
}

class _PlayNjangiSheet extends ConsumerStatefulWidget {
  const _PlayNjangiSheet({required this.group});

  final GroupEntity group;

  @override
  ConsumerState<_PlayNjangiSheet> createState() => _PlayNjangiSheetState();
}

class _PlayNjangiSheetState extends ConsumerState<_PlayNjangiSheet> {
  bool _isLoading = false;

  Future<void> _confirmAndPlay() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(groupRepositoryProvider).playNjangi(widget.group.id);
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
                Text(
                  Formatters.currency(group.contributionAmount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is your fixed group contribution and cannot be changed.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.accent, size: 20),
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
          const SizedBox(height: 20),
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

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value, this.amount});

  final String label;
  final String value;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      color: AppColors.white,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
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
          amount != null
              ? BalanceText(
                  amount!,
                  style: valueStyle,
                  iconColor: AppColors.white,
                )
              : Text(value, style: valueStyle),
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
    final canAssignPicking = group.memberCount >= 2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isPresident)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showEditGroupSettingsDialog(context, ref, group),
              icon: const Icon(Icons.settings),
              label: const Text('Edit group settings'),
            ),
          ),
        if (isPresident) ...[
          _PendingMembershipRequests(group: group),
          const SizedBox(height: 8),
        ],
        _InfoRow(
          'Contribution',
          Formatters.currency(group.contributionAmount),
          amount: group.contributionAmount,
        ),
        _InfoRow('Frequency', group.frequency),
        _InfoRow('Start Date', Formatters.date(group.startDate)),
        _InfoRow('Duration', '${group.durationMonths} months'),
        _InfoRow('Exhaustion Date', Formatters.date(group.effectiveEndDate)),
        if (group.targetAmount != null)
          _InfoRow(
            'Target Picking Amount',
            Formatters.currency(group.targetAmount!),
            amount: group.targetAmount!,
          ),
        _InfoRow('Pickers per Cycle', '${group.pickersPerCycle}'),
        _InfoRow('Cycle Progress', '${group.cycleProgress}/${group.maxMembers}'),
        if (isPresident && group.invitationCode != null)
          _InviteCodeRow(code: group.invitationCode!),
        if (group.rules != null) ...[
          const SizedBox(height: 16),
          Text('Rules', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(group.rules!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (isPresident) ...[
          const SizedBox(height: 24),
          Text(
            group.scheduleGenerated ? 'Re-assign Picking Order' : 'Picking Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (group.scheduleGenerated && !group.rotationStarted)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'A picking order has already been assigned. You can re-run picking '
                'below — this will overwrite the current order.',
              ),
            ),
          if (group.rotationStarted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Picking order is locked — the rotation has started.',
              ),
            )
          else if (!canAssignPicking)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'At least two members are needed to assign the picking order.',
              ),
            )
          else
            _PickingOrderActions(group: group),
        ],
      ],
    );
  }

  void _showEditGroupSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    GroupEntity group,
  ) {
    final controller = TextEditingController(text: '${group.maxMembers}');
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit Group Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Maximum Members',
                controller: controller,
                keyboardType: TextInputType.number,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
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
                      final value = int.tryParse(controller.text.trim());
                      if (value == null || value < 1) {
                        setState(() => errorText = 'Enter a valid number.');
                        return;
                      }
                      if (value < group.memberCount) {
                        setState(() => errorText =
                            'Maximum members cannot be less than the current '
                            'member count (${group.memberCount}).');
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(groupRepositoryProvider).updateGroupSettings(
                              groupId: group.id,
                              maxMembers: value,
                            );
                        ref.invalidate(groupsProvider);
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        final message =
                            e is ApiException ? e.message : AppStrings.genericError;
                        setState(() {
                          isLoading = false;
                          errorText = message;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMembershipRequests extends ConsumerWidget {
  const _PendingMembershipRequests({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(membershipRequestsProvider(group.id));

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.purpleSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Membership Requests',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final request in requests)
                _MembershipRequestTile(group: group, request: request),
            ],
          ),
        );
      },
    );
  }
}

class _MembershipRequestTile extends ConsumerStatefulWidget {
  const _MembershipRequestTile({required this.group, required this.request});

  final GroupEntity group;
  final MembershipRequestEntity request;

  @override
  ConsumerState<_MembershipRequestTile> createState() => _MembershipRequestTileState();
}

class _MembershipRequestTileState extends ConsumerState<_MembershipRequestTile> {
  bool _isLoading = false;

  Future<void> _respond(String decision) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).respondToMembershipRequest(
            groupId: widget.group.id,
            requestId: widget.request.id,
            decision: decision,
          );
      ref.invalidate(membershipRequestsProvider(widget.group.id));
      ref.invalidate(groupsProvider);
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.request.userName),
      trailing: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AppColors.success),
                  onPressed: () => _respond('accept'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () => _respond('reject'),
                ),
              ],
            ),
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
  // 'random' or 'manual' — drives whether re-shuffle is offered.
  String _mode = 'manual';
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _order = _initialOrder();
  }

  List<GroupMemberEntity> _initialOrder() {
    final members = List.of(widget.group.members);
    // Pre-populate with the existing rotation order where available, then
    // append any members who don't have a position yet.
    final positioned = members.where((m) => m.rotationPosition != null).toList()
      ..sort((a, b) => a.rotationPosition!.compareTo(b.rotationPosition!));
    final unpositioned = members.where((m) => m.rotationPosition == null).toList();
    return [...positioned, ...unpositioned];
  }

  void _shuffle() {
    setState(() {
      _order = List.of(widget.group.members)..shuffle();
      _mode = 'random';
      _hasDraft = true;
    });
  }

  void _startManual() {
    setState(() {
      _order = _initialOrder();
      _mode = 'manual';
      _hasDraft = true;
    });
  }

  void _cancelDraft() {
    setState(() {
      _order = _initialOrder();
      _hasDraft = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).assignPickingOrder(
            groupId: widget.group.id,
            mode: _mode,
            order: _order.map((m) => m.id).toList(),
          );
      ref.invalidate(groupsProvider);
      if (mounted) {
        setState(() => _hasDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picking order saved!')),
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
        if (!_hasDraft) ...[
          CustomButton(
            label: 'Pick Randomly',
            icon: Icons.shuffle,
            isLoading: _isLoading,
            onPressed: _shuffle,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Arrange Manually',
            icon: Icons.reorder,
            isOutlined: true,
            isLoading: _isLoading,
            onPressed: _startManual,
          ),
        ] else ...[
          Text(
            _mode == 'random' ? 'Random Draft Order' : 'Manual Draft Order',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _mode == 'random'
                ? 'Review the shuffled order below. Re-shuffle for a new draft, '
                    'or save to apply it.'
                : 'Drag members to set the picking order, then save to apply it.',
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
                _mode = 'manual';
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
          Row(
            children: [
              if (_mode == 'random')
                Expanded(
                  child: CustomButton(
                    label: 'Re-shuffle',
                    icon: Icons.shuffle,
                    isOutlined: true,
                    isLoading: _isLoading,
                    onPressed: _shuffle,
                  ),
                ),
              if (_mode == 'random') const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  label: 'Cancel',
                  isOutlined: true,
                  isLoading: _isLoading,
                  onPressed: _cancelDraft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  label: 'Save',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ),
            ],
          ),
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
          BalanceText(
            fund.balance,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (fund.targetAmount != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Target: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                BalanceText(
                  fund.targetAmount!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
                trailing: BalanceText(c.amount),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavingsTab extends ConsumerWidget {
  const _SavingsTab({required this.group});

  final GroupEntity group;

  bool _isPresident(WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return false;
    final membership = group.members.where((m) => m.id == user.id);
    return membership.isNotEmpty && membership.first.role == GroupRole.president;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresident = _isPresident(ref);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupSavingsProvider(group.id)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: GroupSavingsPanel(groupId: group.id, isPresident: isPresident),
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.group});

  final GroupEntity group;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ref.read(groupRepositoryProvider).sendGroupMessage(
            groupId: widget.group.id,
            message: text,
          );
      _controller.clear();
      ref.invalidate(groupMessagesProvider(widget.group.id));
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupMessagesProvider(widget.group.id));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(child: Text('No messages yet. Say hello!'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(groupMessagesProvider(widget.group.id)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.userId == currentUser?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.purpleSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.userName,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                              ),
                            Text(msg.message, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.dateTime(msg.createdAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Message',
                    controller: _controller,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Invite Code', style: Theme.of(context).textTheme.bodyMedium),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(code, style: Theme.of(context).textTheme.titleSmall),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy invite code',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied to clipboard')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18),
                tooltip: 'Share invite code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: 'Join my Njangi group using invite code: $code'),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite message copied to clipboard')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.amount});

  final String label;
  final String value;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          amount != null
              ? BalanceText(amount!, style: valueStyle)
              : Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
