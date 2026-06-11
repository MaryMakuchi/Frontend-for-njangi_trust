import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/payment_method_selector.dart';

class MakeContributionScreen extends ConsumerStatefulWidget {
  const MakeContributionScreen({super.key});

  @override
  ConsumerState<MakeContributionScreen> createState() =>
      _MakeContributionScreenState();
}

class _MakeContributionScreenState extends ConsumerState<MakeContributionScreen> {
  final _amountController = TextEditingController();
  String? _selectedGroupId;
  String _paymentMethod = AppConstants.paymentMethods.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
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

    setState(() => _isLoading = true);
    try {
      final txn = await ref.read(contributionRepositoryProvider).makeContribution(
            groupId: _selectedGroupId!,
            amount: double.parse(_amountController.text.replaceAll(',', '')),
            paymentMethod: _paymentMethod,
          );
      ref.read(lastPaymentProvider.notifier).state = txn;
      ref.invalidate(contributionsProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) context.push('${AppRoutes.contributions}/success');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Amount (CFA)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: Validators.amount,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  prefixIcon: const Icon(Icons.attach_money),
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
                PaymentMethodSelector(
                  selected: _paymentMethod,
                  onSelected: (m) => setState(() => _paymentMethod = m),
                ),
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
                  onPressed: _pay,
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
