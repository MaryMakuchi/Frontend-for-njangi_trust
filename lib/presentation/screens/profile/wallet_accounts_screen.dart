import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/linked_account_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_text_field.dart';

class WalletAccountsScreen extends ConsumerWidget {
  const WalletAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Accounts')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(linkedAccountsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (dashboard) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(dashboard.walletBalance),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Savings Balance: ${Formatters.currency(dashboard.savingsBalance)}',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTopUpDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Top Up Wallet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, ref, accountsAsync.valueOrNull ?? []),
                    icon: const Icon(Icons.south_east),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Linked Accounts', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _showAddAccountDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No linked accounts yet. Add one to get started.'),
                  );
                }
                return Column(
                  children: accounts
                      .map((a) => _LinkedAccountTile(account: a))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Top Up Wallet'),
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
                      final amount = double.tryParse(controller.text.replaceAll(',', ''));
                      if (amount == null || amount <= 0) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(walletRepositoryProvider).topUpWallet(amount);
                        ref.invalidate(dashboardProvider);
                        ref.read(authStateProvider.notifier).refreshUser();
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message = e is ApiException ? e.message : AppStrings.genericError;
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
                  : const Text('Top Up'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    WidgetRef ref,
    List<LinkedAccountEntity> accounts,
  ) {
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a linked account before withdrawing.')),
      );
      return;
    }

    final controller = TextEditingController();
    bool isLoading = false;
    String? selectedAccountId = accounts.first.id;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Withdraw from Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Amount (CFA)',
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                decoration: const InputDecoration(labelText: 'To Account'),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.provider} - ${a.accountNumber}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedAccountId = v),
              ),
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
                      final amount = double.tryParse(controller.text.replaceAll(',', ''));
                      if (amount == null || amount <= 0 || selectedAccountId == null) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(walletRepositoryProvider).withdrawWallet(
                              amount: amount,
                              linkedAccountId: selectedAccountId!,
                            );
                        ref.invalidate(dashboardProvider);
                        ref.read(authStateProvider.notifier).refreshUser();
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message = e is ApiException ? e.message : AppStrings.genericError;
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
                  : const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final providerController = TextEditingController();
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    LinkedAccountType accountType = LinkedAccountType.mobileMoney;
    bool isDefault = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Add Linked Account'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<LinkedAccountType>(
                    initialValue: accountType,
                    decoration: const InputDecoration(labelText: 'Account Type'),
                    items: const [
                      DropdownMenuItem(
                        value: LinkedAccountType.mobileMoney,
                        child: Text('Mobile Money'),
                      ),
                      DropdownMenuItem(
                        value: LinkedAccountType.bank,
                        child: Text('Bank Account'),
                      ),
                    ],
                    onChanged: (v) => setState(() => accountType = v ?? accountType),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Provider (e.g. MTN MoMo, Orange Money)',
                    controller: providerController,
                    validator: (v) => Validators.required(v, field: 'Provider'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Account Number',
                    controller: numberController,
                    keyboardType: TextInputType.text,
                    validator: (v) => Validators.required(v, field: 'Account number'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Account Name',
                    controller: nameController,
                    validator: (v) => Validators.required(v, field: 'Account name'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDefault,
                    title: const Text('Set as default account'),
                    onChanged: (v) => setState(() => isDefault = v ?? false),
                  ),
                ],
              ),
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
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(walletRepositoryProvider).addLinkedAccount(
                              accountType: accountType,
                              provider: providerController.text.trim(),
                              accountNumber: numberController.text.trim(),
                              accountName: nameController.text.trim(),
                              isDefault: isDefault,
                            );
                        ref.invalidate(linkedAccountsProvider);
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message = e is ApiException ? e.message : AppStrings.genericError;
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
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountTile extends ConsumerWidget {
  const _LinkedAccountTile({required this.account});

  final LinkedAccountEntity account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              account.accountType == LinkedAccountType.mobileMoney
                  ? Icons.phone_android
                  : Icons.account_balance,
              color: AppColors.purple,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(account.provider, style: Theme.of(context).textTheme.titleSmall),
                    if (account.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(color: AppColors.accent, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(account.accountNumber, style: Theme.of(context).textTheme.bodySmall),
                Text(account.accountName, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              try {
                await ref.read(walletRepositoryProvider).deleteLinkedAccount(account.id);
                ref.invalidate(linkedAccountsProvider);
              } catch (e) {
                if (context.mounted) {
                  final message = e is ApiException ? e.message : AppStrings.genericError;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
