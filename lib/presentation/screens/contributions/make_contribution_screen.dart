import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/loan_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/payment_method_selector.dart';

enum _ContributionTarget { njangi, socialFund, loanRepayment }

class MakeContributionScreen extends ConsumerStatefulWidget {
  const MakeContributionScreen({super.key});

  @override
  ConsumerState<MakeContributionScreen> createState() =>
      _MakeContributionScreenState();
}

class _MakeContributionScreenState extends ConsumerState<MakeContributionScreen> {
  final _amountController = TextEditingController();
  final _momoController = TextEditingController();
  String? _selectedGroupId;
  String _paymentMethod = AppConstants.paymentMethods.first;
  bool _isLoading = false;
  _ContributionTarget _target = _ContributionTarget.njangi;
  String? _selectedFundId;
  String? _selectedLoanId;

  bool get _needsMomoNumber =>
      _paymentMethod == 'MTN MoMo' || _paymentMethod == 'Orange Money';

  @override
  void dispose() {
    _amountController.dispose();
    _momoController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group')),
      );
      return;
    }
    if (Validators.amount(_amountController.text) != null) return;

    if (_target == _ContributionTarget.socialFund && _selectedFundId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a social fund')),
      );
      return;
    }

    if (_target == _ContributionTarget.loanRepayment && _selectedLoanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a loan to repay')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      if (_target == _ContributionTarget.loanRepayment) {
        final loan = await ref.read(loanRepositoryProvider).repayLoan(
              loanId: _selectedLoanId!,
              amount: amount,
            );
        ref.read(lastPaymentProvider.notifier).state = TransactionEntity(
          id: loan.id,
          title: 'Loan Repayment - ${loan.purpose}',
          amount: amount,
          type: TransactionType.loanRepayment,
          status: TransactionStatus.completed,
          date: DateTime.now(),
          groupName: loan.groupName,
        );
        ref.invalidate(loansProvider);
        ref.read(authStateProvider.notifier).refreshUser();
      } else if (_target == _ContributionTarget.socialFund) {
        final fund = await ref.read(groupRepositoryProvider).contributeSocialFund(
              groupId: _selectedGroupId!,
              fundId: _selectedFundId!,
              amount: amount,
            );
        ref.read(lastPaymentProvider.notifier).state = TransactionEntity(
          id: fund.id,
          title: 'Social Fund Contribution - ${fund.reason}',
          amount: amount,
          type: TransactionType.socialFund,
          status: TransactionStatus.verified,
          date: DateTime.now(),
          groupName: fund.groupName,
        );
        ref.invalidate(groupSocialFundsProvider(_selectedGroupId!));
      } else {
        final txn = await ref.read(contributionRepositoryProvider).makeContribution(
              groupId: _selectedGroupId!,
              amount: amount,
              paymentMethod: _paymentMethod,
            );
        ref.read(lastPaymentProvider.notifier).state = txn;
        ref.invalidate(contributionsProvider);
      }
      ref.invalidate(dashboardProvider);
      if (mounted) context.push('${AppRoutes.contributions}/success');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canSubmit {
    if (_target == _ContributionTarget.socialFund && _selectedFundId == null) {
      return false;
    }
    if (_target == _ContributionTarget.loanRepayment && _selectedLoanId == null) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Make Contribution')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          _selectedGroupId ??= groups.isNotEmpty ? groups.first.id : null;

          // Load social funds and loans to determine which types are available.
          final fundsAsync = _selectedGroupId != null
              ? ref.watch(groupSocialFundsProvider(_selectedGroupId!))
              : null;
          final loansAsync = ref.watch(loansProvider);
          final hasFunds = fundsAsync?.valueOrNull?.any((f) => f.isActive) ?? true;
          final hasLoans = loansAsync.valueOrNull
                  ?.any((l) => l.status == LoanStatus.active) ??
              true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Group', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: groups
                      .map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedGroupId = v;
                    _selectedFundId = null;
                  }),
                ),
                if (_selectedGroupId != null) ...[
                  const SizedBox(height: 20),
                  Text('Contribution Type', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ContributionTypeCard(
                          icon: Icons.repeat,
                          label: 'Njangi',
                          isSelected: _target == _ContributionTarget.njangi,
                          onTap: () => setState(() => _target = _ContributionTarget.njangi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContributionTypeCard(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'Social Fund',
                          isSelected: _target == _ContributionTarget.socialFund,
                          disabled: !hasFunds,
                          onTap: () => setState(() => _target = _ContributionTarget.socialFund),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContributionTypeCard(
                          icon: Icons.account_balance_outlined,
                          label: 'Loan Repayment',
                          isSelected: _target == _ContributionTarget.loanRepayment,
                          disabled: !hasLoans,
                          onTap: () => setState(() => _target = _ContributionTarget.loanRepayment),
                        ),
                      ),
                    ],
                  ),
                  if (_target == _ContributionTarget.socialFund)
                    _SocialFundPicker(
                      groupId: _selectedGroupId!,
                      selectedFundId: _selectedFundId,
                      onChanged: (id) => setState(() => _selectedFundId = id),
                    ),
                  if (_target == _ContributionTarget.loanRepayment)
                    _LoanPicker(
                      groupId: _selectedGroupId!,
                      selectedLoanId: _selectedLoanId,
                      onChanged: (id) => setState(() => _selectedLoanId = id),
                    ),
                ],
                const SizedBox(height: 20),
                PaymentMethodSelector(
                  selected: _paymentMethod,
                  onSelected: (m) => setState(() => _paymentMethod = m),
                ),
                if (_needsMomoNumber) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: '${_paymentMethod} Number',
                    controller: _momoController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                  ),
                ],
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Amount (CFA)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: Validators.amount,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                const SizedBox(height: 16),
                Text('Quick Select', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConstants.quickAmounts.map((amount) {
                    return ActionChip(
                      label: Text(Formatters.currency(amount, showSymbol: false)),
                      onPressed: () {
                        _amountController.text =
                            Formatters.currency(amount, showSymbol: false);
                      },
                      backgroundColor: AppColors.purpleSurface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MRI Impact: +0.2 on successful payment',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Pay Now',
                  isLoading: _isLoading,
                  onPressed: _canSubmit ? _pay : null,
                  gradient: AppColors.purpleGradient,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContributionTypeCard extends StatelessWidget {
  const _ContributionTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.mediumGray,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanPicker extends ConsumerWidget {
  const _LoanPicker({
    required this.groupId,
    required this.selectedLoanId,
    required this.onChanged,
  });

  final String groupId;
  final String? selectedLoanId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: loansAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(
          'Failed to load loans: $e',
          style: const TextStyle(color: AppColors.error),
        ),
        data: (loans) {
          // Only active loans for the selected group can be repaid here.
          final repayable = loans
              .where((l) =>
                  l.status == LoanStatus.active &&
                  (l.groupId == null || l.groupId == groupId))
              .toList();

          if (repayable.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.mediumGray, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('You have no active loans to repay in this group.'),
                  ),
                ],
              ),
            );
          }

          if (selectedLoanId == null ||
              !repayable.any((l) => l.id == selectedLoanId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(repayable.first.id);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Select Loan', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: repayable.any((l) => l.id == selectedLoanId)
                    ? selectedLoanId
                    : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: repayable
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            '${l.purpose} • Balance '
                            '${Formatters.currency(l.remainingBalance ?? l.amount, showSymbol: false)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SocialFundPicker extends ConsumerWidget {
  const _SocialFundPicker({
    required this.groupId,
    required this.selectedFundId,
    required this.onChanged,
  });

  final String groupId;
  final String? selectedFundId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(groupSocialFundsProvider(groupId));

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: fundsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(
          'Failed to load social funds: $e',
          style: const TextStyle(color: AppColors.error),
        ),
        data: (funds) {
          final activeFunds = funds.where((f) => f.isActive).toList();
          if (activeFunds.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purpleSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.mediumGray, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('This group has no active social funds.'),
                  ),
                ],
              ),
            );
          }

          if (selectedFundId == null ||
              !activeFunds.any((f) => f.id == selectedFundId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(activeFunds.first.id);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Social Fund', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: activeFunds.any((f) => f.id == selectedFundId)
                    ? selectedFundId
                    : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.volunteer_activism_outlined),
                ),
                items: activeFunds
                    .map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(
                            '${f.reason} (${Formatters.currency(f.balance, showSymbol: false)}'
                            '${f.targetAmount != null ? ' / ${Formatters.currency(f.targetAmount!, showSymbol: false)}' : ''})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}
