import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/njangi_hype.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/membership_request_entity.dart';
import '../../../domain/entities/social_fund_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/group_savings_panel.dart';
import '../../routes/app_router.dart';

class GroupDetailsScreen extends ConsumerWidget {
  const GroupDetailsScreen({super.key, required this.groupId, this.initialTab});

  final String groupId;

  /// Optional tab to open on first build (e.g. 'members' from a notification
  /// deep-link). Defaults to the Overview tab when null/unknown.
  final String? initialTab;

  static const _tabOrder = [
    'overview',
    'members',
    'social fund',
    'ledger',
    'savings',
    'loans',
    'chat',
  ];

  int get _initialIndex {
    if (initialTab == null) return 0;
    final i = _tabOrder.indexOf(initialTab!.toLowerCase());
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          final matches = groups.where((g) => g.id == groupId);
          if (matches.isEmpty) {
            // The user isn't (or is no longer) a member of this group — e.g.
            // they followed a stale notification link. Show a friendly message
            // instead of crashing with a red error screen.
            return _NotAMember(onBack: () => context.go(AppRoutes.home));
          }
          final group = matches.first;
          return DefaultTabController(
            length: 7,
            initialIndex: _initialIndex,
            // NestedScrollView lets the header scroll away ("collapse up")
            // while the tab bar stays pinned, giving more room to read each tab.
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _GroupHeader(group: group)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedTabBarDelegate(
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
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OverviewTab(group: group),
                  _MembersTab(group: group),
                  _SocialFundTab(group: group),
                  _LedgerTab(group: group),
                  _SavingsTab(group: group),
                  const Center(child: Text('Group loans coming soon')),
                  _ChatTab(group: group),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the current user isn't a member of the requested group, instead
/// of letting the screen crash on missing data.
class _NotAMember extends StatelessWidget {
  const _NotAMember({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.mediumGray),
            const SizedBox(height: 16),
            const Text(
              'You are not a member of this group.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'It may have been removed, or your request was not accepted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the tab bar pinned at the top while the group header scrolls away.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: AppColors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
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
  String _source = 'wallet';

  static const _paymentSources = [
    ('wallet', 'Wallet', Icons.account_balance_wallet_outlined),
    ('momo', 'MoMo', Icons.phone_android_outlined),
    ('bank', 'Bank', Icons.account_balance_outlined),
  ];

  Future<void> _confirmAndPlay() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(groupRepositoryProvider)
          .playNjangi(widget.group.id, source: _source);
      ref.invalidate(groupsProvider);
      ref.invalidate(dashboardProvider);
      // Reflect the new contribution in the group ledger and global ledger
      // immediately, with its payment timestamp.
      ref.invalidate(groupLedgerProvider);
      ref.invalidate(transactionsProvider);

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
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isMyTurn =
        currentPicker != null && currentUser != null && currentPicker.id == currentUser.id;
    final nextPlayDue = group.nextPlayDue;

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
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.mediumGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextPlayDue != null
                      ? '${formatDueDateTime(nextPlayDue)} · ${relativeDueLabel(nextPlayDue)}'
                      : 'No schedule set',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMyTurn ? AppColors.successLight : AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isMyTurn ? Icons.celebration : Icons.emoji_events_outlined,
                  color: isMyTurn ? AppColors.accent : AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMyTurn
                        ? njangiHypeMessage()
                        : currentPicker != null
                            ? 'Currently picking: ${currentPicker.name}'
                            : 'Picking order not yet assigned',
                    style: isMyTurn
                        ? const TextStyle(fontWeight: FontWeight.w700)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pay from',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final source in _paymentSources) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => setState(() => _source = source.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _source == source.$1
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _source == source.$1
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            source.$3,
                            size: 22,
                            color: _source == source.$1
                                ? AppColors.primary
                                : AppColors.mediumGray,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _source == source.$1
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _source == source.$1
                                  ? AppColors.primary
                                  : AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (source != _paymentSources.last) const SizedBox(width: 8),
              ],
            ],
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
              ? Text(Formatters.currency(amount!), style: valueStyle)
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
        const SizedBox(height: 12),
        InkWell(
          onTap: () =>
              context.push('${AppRoutes.groupFinances}/${group.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group Finances',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'See expected vs. collected and who has paid this cycle',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mediumGray),
              ],
            ),
          ),
        ),
        // My Slots section - shows all memberships for the current user
        _MySlotsSection(groupId: group.id),

        if (group.rules != null) ...[
          const SizedBox(height: 16),
          Text('Rules', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(group.rules!, style: Theme.of(context).textTheme.bodyMedium),
        ],

        // Board Election section
        _BoardElectionSection(group: group),

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

/// Pending join requests rendered in the Members tab (presidents only),
/// styled like member rows but marked "Pending" with Accept/Reject actions.
class _PendingRequestsSection extends ConsumerWidget {
  const _PendingRequestsSection({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(membershipRequestsProvider(group.id));

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Requests',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final request in requests)
              _MembershipRequestTile(group: group, request: request),
            const SizedBox(height: 8),
            Text(
              'Members',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
          ],
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
    final name = widget.request.userName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.mediumGray.withValues(alpha: 0.2),
        child: Text(name.isNotEmpty ? name[0] : '?'),
      ),
      title: Row(
        children: [
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mediumGray.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(fontSize: 10, color: AppColors.mediumGray),
            ),
          ),
        ],
      ),
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
                  tooltip: 'Accept',
                  icon: const Icon(Icons.check_circle, color: AppColors.success),
                  onPressed: () => _respond('accept'),
                ),
                IconButton(
                  tooltip: 'Reject',
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

  /// Let the server compute a reliability-weighted order. Members with stronger
  /// MRI scores are favoured for the earliest (highest-risk) payout slots, and
  /// clearly unreliable members are kept out of the early window.
  Future<void> _orderByReliability() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order by Reliability?'),
        content: const Text(
          'The picking order will be set automatically from members\' '
          'reliability (MRI) scores. More reliable members are favoured for the '
          'earliest payout positions, which protects the group against early '
          'receivers who might stop contributing.\n\n'
          'You can still re-run picking later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).assignPickingOrder(
            groupId: widget.group.id,
            mode: 'mri_weighted',
          );
      ref.invalidate(groupsProvider);
      if (mounted) {
        setState(() => _hasDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Picking order set by reliability (MRI).'),
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
            label: 'Order by Reliability (MRI)',
            icon: Icons.verified_user_outlined,
            isLoading: _isLoading,
            onPressed: _orderByReliability,
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended: favours reliable members for early payouts and keeps '
            'high-risk members out of the earliest positions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Pick Randomly',
            icon: Icons.shuffle,
            isOutlined: true,
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

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.group});

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isPresident) _PendingRequestsSection(group: group),
        for (var i = 0; i < group.members.length; i++) ...[
          if (i > 0) const Divider(),
          _buildMemberTile(context, group.members[i]),
        ],
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, GroupMemberEntity member) {
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
  }

  String _roleLabel(GroupRole role) {
    switch (role) {
      case GroupRole.president:
        return 'President';
      case GroupRole.vicePresident:
        return 'Vice President';
      case GroupRole.treasurer:
        return 'Treasurer';
      case GroupRole.secretary:
        return 'Secretary';
      case GroupRole.auditor:
        return 'Auditor';
      case GroupRole.member:
        return 'Member';
    }
  }
}

// ─── My Slots Section ───────────────────────────────────────────────────────

final _mySlotsProvider = FutureProvider.autoDispose.family<List<GroupSlotEntity>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).getMySlots(groupId),
);

class _MySlotsSection extends ConsumerWidget {
  const _MySlotsSection({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(_mySlotsProvider(groupId));

    return slotsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (slots) {
        if (slots.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('My Slots in This Group',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final slot in slots)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purpleSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: slot.isCurrentBeneficiary
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        slot.slotName.isNotEmpty ? slot.slotName[0] : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.slotName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            slot.role.replaceAll('_', ' ').toUpperCase() +
                                (slot.rotationPosition != null
                                    ? ' · Position ${slot.rotationPosition}'
                                    : ''),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (slot.isCurrentBeneficiary)
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
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Board Election Section ──────────────────────────────────────────────────

final _electionProvider = FutureProvider.autoDispose.family<ElectionEntity?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).getElection(groupId),
);

class _BoardElectionSection extends ConsumerWidget {
  const _BoardElectionSection({required this.group});

  final GroupEntity group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final myMembership = group.members.where((m) => m.id == user.id);
    final isPresident = myMembership.isNotEmpty &&
        myMembership.first.role == GroupRole.president;

    final electionAsync = ref.watch(_electionProvider(group.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Board Election', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        electionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (election) {
            if (election == null || election.id.isEmpty) {
              // No active election
              if (isPresident) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'No election is currently in progress.',
                      style: TextStyle(color: AppColors.mediumGray),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Start Election',
                      icon: Icons.how_to_vote_outlined,
                      onPressed: () => _startElection(context, ref),
                    ),
                  ],
                );
              }
              return const Text(
                'No board election is currently in progress.',
                style: TextStyle(color: AppColors.mediumGray),
              );
            }

            return _ElectionPanel(group: group, election: election, isPresident: isPresident);
          },
        ),
      ],
    );
  }

  Future<void> _startElection(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupRepositoryProvider).startElection(group.id);
      ref.invalidate(_electionProvider(group.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Election started. Nominations are open.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

class _ElectionPanel extends ConsumerStatefulWidget {
  const _ElectionPanel({
    required this.group,
    required this.election,
    required this.isPresident,
  });

  final GroupEntity group;
  final ElectionEntity election;
  final bool isPresident;

  @override
  ConsumerState<_ElectionPanel> createState() => _ElectionPanelState();
}

class _ElectionPanelState extends ConsumerState<_ElectionPanel> {
  static const _allRoles = [
    'president', 'vice_president', 'treasurer', 'secretary', 'auditor',
  ];
  static const _roleLabels = {
    'president': 'President',
    'vice_president': 'Vice President',
    'treasurer': 'Treasurer',
    'secretary': 'Secretary',
    'auditor': 'Auditor',
  };

  bool _isAdvancing = false;
  bool _isNominating = false;

  final _nomineeController = TextEditingController();
  String _selectedRole = 'president';
  List<UserSearchResultEntity> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nomineeController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ref.read(groupRepositoryProvider).searchUsers(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {} finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _nominate(String username) async {
    setState(() => _isNominating = true);
    try {
      await ref.read(groupRepositoryProvider).nominateForElection(
            groupId: widget.group.id,
            nomineeUsername: username,
            role: _selectedRole,
          );
      ref.invalidate(_electionProvider(widget.group.id));
      _nomineeController.clear();
      setState(() => _searchResults = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nominated $username for ${_roleLabels[_selectedRole]}')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isNominating = false);
    }
  }

  Future<void> _vote(String nomineeId, String role) async {
    try {
      await ref.read(groupRepositoryProvider).voteInElection(
            groupId: widget.group.id,
            nomineeId: nomineeId,
            role: role,
          );
      ref.invalidate(_electionProvider(widget.group.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vote cast for ${_roleLabels[role]}')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _advanceElection() async {
    setState(() => _isAdvancing = true);
    try {
      await ref.read(groupRepositoryProvider).advanceElection(widget.group.id);
      ref.invalidate(_electionProvider(widget.group.id));
      ref.invalidate(groupsProvider);
      if (mounted) {
        final nextStatus = widget.election.status == 'nominations' ? 'voting' : 'complete';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            nextStatus == 'complete'
                ? 'Election complete! Board roles have been assigned.'
                : 'Election advanced to voting phase.',
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isAdvancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final election = widget.election;
    final statusLabel = election.status == 'nominations'
        ? 'Nominations Open'
        : election.status == 'voting'
            ? 'Voting Open'
            : 'Complete';
    final statusColor = election.status == 'nominations'
        ? AppColors.primary
        : election.status == 'voting'
            ? AppColors.accent
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            if (widget.isPresident && election.status != 'complete')
              TextButton(
                onPressed: _isAdvancing ? null : _advanceElection,
                child: _isAdvancing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(election.status == 'nominations'
                        ? 'Start Voting'
                        : 'Finalise Results'),
              ),
          ],
        ),

        // Nominations phase: show nomination form and current nominees
        if (election.status == 'nominations') ...[
          const SizedBox(height: 12),
          Text('Nominate a Member', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder(), isDense: true),
            items: _allRoles
                .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabels[r]!)))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Search by username',
            controller: _nomineeController,
            onChanged: _searchUsers,
          ),
          if (_isSearching) const LinearProgressIndicator(),
          if (_searchResults.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _searchResults.map((u) => ListTile(
                  dense: true,
                  title: Text(u.name),
                  subtitle: Text('@${u.username}'),
                  trailing: _isNominating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline, size: 20),
                  onTap: _isNominating ? null : () => _nominate(u.username),
                )).toList(),
              ),
            ),
        ],

        // Show nominees for all roles
        const SizedBox(height: 12),
        for (final role in _allRoles) ...[
          if (election.nominations.containsKey(role) &&
              election.nominations[role]!.isNotEmpty) ...[
            Text(
              _roleLabels[role]!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            for (final nominee in election.nominations[role]!) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purpleSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(nominee.nomineeName[0]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nominee.nomineeName,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${nominee.nominationCount} nomination(s)',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (election.status == 'voting')
                      election.myVotes[role] == nominee.nomineeId
                          ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                          : TextButton(
                              onPressed: () => _vote(nominee.nomineeId, role),
                              child: const Text('Vote'),
                            ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Target: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  Formatters.currency(fund.targetAmount!),
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
                trailing: Text(Formatters.currency(c.amount)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerTab extends ConsumerStatefulWidget {
  const _LedgerTab({required this.group});

  final GroupEntity group;

  @override
  ConsumerState<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends ConsumerState<_LedgerTab> {
  static const _categories = [
    ('all', 'All'),
    ('njangi', 'Njangi'),
    ('savings', 'Savings'),
    ('loans', 'Loans'),
    ('social_fund', 'Social Fund'),
  ];

  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(
      groupLedgerProvider((groupId: widget.group.id, category: _category)),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c.$1, child: Text(c.$2)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
        ),
        Expanded(
          child: ledgerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No transactions in this category yet'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  groupLedgerProvider(
                    (groupId: widget.group.id, category: _category),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _LedgerTile(transaction: transactions[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
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
          Row(
            children: [
              Expanded(
                child: Text(t.title, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (t.onChain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'On-chain',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${t.isCredit ? '+' : '-'}${Formatters.currency(t.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.isCredit ? AppColors.success : AppColors.error,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.dateTime(t.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (t.initiatedBy != null && t.initiatedBy!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.mediumGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'By ${t.initiatedBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGray,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (t.onChain && t.explorerUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(t.explorerUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: AppColors.purple),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      t.hash ?? 'View on explorer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.purple,
                            decoration: TextDecoration.underline,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 14, color: AppColors.purple),
                ],
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
              ? Text(Formatters.currency(amount!), style: valueStyle)
              : Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
