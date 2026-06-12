import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/api_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../domain/entities/savings_entity.dart';
import '../providers/providers.dart';
import 'balance_text.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

/// Reusable panel showing the group savings period for a single group:
/// empty state (start a period), active period (deposit/withdraw/close),
/// or closed period (withdraw final totals).
///
/// Used by both the standalone Savings screen (profile tab) and the
/// per-group "Savings" tab on the group details screen.
class GroupSavingsPanel extends ConsumerWidget {
  const GroupSavingsPanel({
    super.key,
    required this.groupId,
    required this.isPresident,
  });

  final String groupId;
  final bool isPresident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(groupSavingsProvider(groupId));

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
          return _EmptyPeriodState(groupId: groupId, isPresident: isPresident);
        }

        if (period.isClosed) {
          return _ClosedPeriodView(groupId: groupId, period: period, savings: savings.mySavings);
        }

        return _ActivePeriodView(
          groupId: groupId,
          period: period,
          savings: savings.mySavings,
          isPresident: isPresident,
        );
      },
    );
  }
}

class _EmptyPeriodState extends StatelessWidget {
  const _EmptyPeriodState({required this.groupId, required this.isPresident});

  final String groupId;
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
              onPressed: () => _showStartPeriodDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showStartPeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _StartPeriodDialog(groupId: groupId),
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
    required this.groupId,
    required this.period,
    required this.savings,
    required this.isPresident,
  });

  final String groupId;
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
    showDialog(
      context: context,
      builder: (dialogContext) => _DepositDialog(groupId: groupId),
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
                await ref.read(groupRepositoryProvider).closeSavingsPeriod(groupId);
                ref.invalidate(groupSavingsProvider(groupId));
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

/// Deposit dialog with a "Deposit from" source selector
/// (Wallet / MoMo / Bank). For momo/bank the backend collects the funds
/// from the chosen channel, so the wallet balance is not used.
class _DepositDialog extends ConsumerStatefulWidget {
  const _DepositDialog({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends ConsumerState<_DepositDialog> {
  final _controller = TextEditingController();
  String _source = 'wallet';
  bool _isLoading = false;

  static const _sources = [
    (value: 'wallet', label: 'Wallet', icon: Icons.account_balance_wallet_outlined),
    (value: 'momo', label: 'Mobile Money', icon: Icons.phone_android),
    (value: 'bank', label: 'Bank', icon: Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_controller.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).depositToGroupSavings(
            groupId: widget.groupId,
            amount: amount,
            source: _source,
          );
      ref.invalidate(groupSavingsProvider(widget.groupId));
      ref.invalidate(dashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notWallet = _source != 'wallet';
    return AlertDialog(
      title: const Text('Deposit to Savings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Amount (CFA)',
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
            ),
            const SizedBox(height: 16),
            Text('Deposit from', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._sources.map(
              (s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: _source == s.value
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _source == s.value
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: RadioListTile<String>(
                  value: s.value,
                  groupValue: _source,
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _source = v ?? 'wallet'),
                  title: Text(s.label),
                  secondary: Icon(s.icon),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                ),
              ),
            ),
            if (notWallet)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _source == 'momo'
                      ? 'Funds collected from your Mobile Money.'
                      : 'Funds collected from your Bank.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
              : const Text('Deposit'),
        ),
      ],
    );
  }
}

class _ClosedPeriodView extends ConsumerWidget {
  const _ClosedPeriodView({
    required this.groupId,
    required this.period,
    required this.savings,
  });

  final String groupId;
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
      final result = await ref.read(groupRepositoryProvider).withdrawGroupSavings(groupId);
      ref.invalidate(groupSavingsProvider(groupId));
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
