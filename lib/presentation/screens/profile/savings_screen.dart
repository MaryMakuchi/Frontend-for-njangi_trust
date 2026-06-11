import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/savings_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/balance_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You are not a member of any group yet. Join or create a '
                  'group to start saving.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedId = _selectedGroupId ?? groups.first.id;
          final selectedGroup = groups.firstWhere(
            (g) => g.id == selectedId,
            orElse: () => groups.first,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupSavingsProvider(selectedGroup.id));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groups.length > 1) ...[
                    Text('Group', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroup.id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedGroupId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _GroupSavingsContent(group: selectedGroup),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroupSavingsContent extends ConsumerWidget {
  const _GroupSavingsContent({required this.group});

  final GroupEntity group;

  bool _isPresident(WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return false;
    final membership = group.members.where((m) => m.id == user.id);
    return membership.isNotEmpty && membership.first.role == GroupRole.president;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(groupSavingsProvider(group.id));
    final isPresident = _isPresident(ref);

    return savingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Error: $e')),
      ),
      data: (savings) {
        final period = savings.period;

        if (period == null) {
          return _EmptyPeriodState(group: group, isPresident: isPresident);
        }

        if (period.isClosed) {
          return _ClosedPeriodView(group: group, period: period, savings: savings.mySavings);
        }

        return _ActivePeriodView(
          group: group,
          period: period,
          savings: savings.mySavings,
          isPresident: isPresident,
        );
      },
    );
  }
}

class _EmptyPeriodState extends StatelessWidget {
  const _EmptyPeriodState({required this.group, required this.isPresident});

  final GroupEntity group;
  final bool isPresident;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.purpleSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Savings Period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'This group has not started a savings period yet.',
          ),
          if (isPresident) ...[
            const SizedBox(height: 16),
            CustomButton(
              label: 'Start Savings Period',
              icon: Icons.savings_outlined,
              onPressed: () => _showStartPeriodDialog(context, group),
            ),
          ],
        ],
      ),
    );
  }

  void _showStartPeriodDialog(BuildContext context, GroupEntity group) {
    showDialog(
      context: context,
      builder: (dialogContext) => _StartPeriodDialog(groupId: group.id),
    );
  }
}

class _StartPeriodDialog extends ConsumerStatefulWidget {
  const _StartPeriodDialog({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_StartPeriodDialog> createState() => _StartPeriodDialogState();
}

class _StartPeriodDialogState extends ConsumerState<_StartPeriodDialog> {
  final _rateController = TextEditingController();
  String _interestType = 'simple';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate < 0) {
      setState(() => _errorText = 'Enter a valid interest rate.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(() => _errorText = 'Select start and end dates.');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      setState(() => _errorText = 'End date must be after start date.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(groupRepositoryProvider).startSavingsPeriod(
            groupId: widget.groupId,
            interestRate: rate,
            interestType: _interestType,
            startDate: _startDate!,
            endDate: _endDate!,
          );
      ref.invalidate(groupSavingsProvider(widget.groupId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      final message = e is ApiException ? e.message : AppStrings.genericError;
      setState(() {
        _isLoading = false;
        _errorText = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Savings Period'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Interest Rate (%)',
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            const Text('Interest Type'),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'simple', label: Text('Simple')),
                ButtonSegment(value: 'compound', label: Text('Compound')),
              ],
              selected: {_interestType},
              onSelectionChanged: (selection) {
                setState(() => _interestType = selection.first);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(
                _startDate == null ? 'Not set' : Formatters.date(_startDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End Date'),
              subtitle: Text(
                _endDate == null ? 'Not set' : Formatters.date(_endDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start'),
        ),
      ],
    );
  }
}

class _ActivePeriodView extends ConsumerWidget {
  const _ActivePeriodView({
    required this.group,
    required this.period,
    required this.savings,
    required this.isPresident,
  });

  final GroupEntity group;
  final SavingsPeriodEntity period;
  final SavingsSummaryEntity? savings;
  final bool isPresident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Savings', style: TextStyle(color: AppColors.white)),
              const SizedBox(height: 8),
              BalanceText(
                savings?.total ?? 0,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                iconColor: AppColors.white,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Principal: ', style: TextStyle(color: AppColors.white)),
                  BalanceText(
                    savings?.principal ?? 0,
                    style: const TextStyle(color: AppColors.white),
                    iconColor: AppColors.white,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Interest accrued: ',
                      style: TextStyle(color: AppColors.white)),
                  BalanceText(
                    savings?.interestAccrued ?? 0,
                    style: const TextStyle(color: AppColors.white),
                    iconColor: AppColors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.purpleSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Savings Period', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _InfoRow('Interest Rate', '${period.interestRate.toStringAsFixed(2)}%'),
              _InfoRow(
                'Interest Type',
                period.interestType == 'compound' ? 'Compound' : 'Simple',
              ),
              _InfoRow('Start Date', Formatters.date(period.startDate)),
              _InfoRow('End Date', Formatters.date(period.endDate)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Deposit',
                icon: Icons.south_west,
                onPressed: () => _showDepositDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label:
                    'Available when the savings period ends on ${Formatters.date(period.endDate)}',
                icon: Icons.north_east,
                isOutlined: true,
                onPressed: null,
              ),
            ),
          ],
        ),
        if (isPresident) ...[
          const SizedBox(height: 12),
          CustomButton(
            label: 'Close period early',
            icon: Icons.lock_clock,
            isOutlined: true,
            onPressed: () => _confirmClosePeriod(context, ref),
          ),
        ],
        if (savings != null && savings!.deposits.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Deposits', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...savings!.deposits.map(
            (d) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.south_west, color: AppColors.success),
              title: BalanceText(d.amount),
              subtitle: Text(Formatters.date(d.date)),
            ),
          ),
        ],
      ],
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Deposit to Savings'),
          content: CustomTextField(
            label: 'Amount (CFA)',
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
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
                      final amount =
                          double.tryParse(controller.text.replaceAll(',', ''));
                      if (amount == null || amount <= 0) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(groupRepositoryProvider).depositToGroupSavings(
                              groupId: group.id,
                              amount: amount,
                            );
                        ref.invalidate(groupSavingsProvider(group.id));
                        ref.invalidate(dashboardProvider);
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message = e is ApiException
                              ? e.message
                              : AppStrings.genericError;
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
                  : const Text('Deposit'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClosePeriod(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close Savings Period'),
        content: const Text(
          'This will close the savings period early for everyone in the group. '
          'Members will then be able to withdraw their savings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(groupRepositoryProvider).closeSavingsPeriod(group.id);
                ref.invalidate(groupSavingsProvider(group.id));
              } catch (e) {
                if (context.mounted) {
                  final message =
                      e is ApiException ? e.message : AppStrings.genericError;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
            child: const Text('Close Period'),
          ),
        ],
      ),
    );
  }
}

class _ClosedPeriodView extends ConsumerWidget {
  const _ClosedPeriodView({
    required this.group,
    required this.period,
    required this.savings,
  });

  final GroupEntity group;
  final SavingsPeriodEntity period;
  final SavingsSummaryEntity? savings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Savings Period Closed', style: TextStyle(color: AppColors.white)),
              const SizedBox(height: 8),
              BalanceText(
                savings?.total ?? 0,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                iconColor: AppColors.white,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Principal: ', style: TextStyle(color: AppColors.white)),
                  BalanceText(
                    savings?.principal ?? 0,
                    style: const TextStyle(color: AppColors.white),
                    iconColor: AppColors.white,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Interest accrued: ',
                      style: TextStyle(color: AppColors.white)),
                  BalanceText(
                    savings?.interestAccrued ?? 0,
                    style: const TextStyle(color: AppColors.white),
                    iconColor: AppColors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          label: 'Withdraw',
          icon: Icons.north_east,
          onPressed: () => _withdraw(context, ref),
        ),
      ],
    );
  }

  void _withdraw(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(groupRepositoryProvider).withdrawGroupSavings(group.id);
      ref.invalidate(groupSavingsProvider(group.id));
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Withdrew ${Formatters.currency(result.amountWithdrawn)} to your wallet.',
            ),
          ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
