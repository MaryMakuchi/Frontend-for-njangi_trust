import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../domain/entities/loan_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  Color _statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.approved:
      case LoanStatus.active:
        return AppColors.success;
      case LoanStatus.pending:
        return AppColors.warning;
      case LoanStatus.rejected:
        return AppColors.error;
      case LoanStatus.repaid:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);
    final maxAmountAsync = ref.watch(maxLoanAmountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (loans) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(loansProvider);
            ref.invalidate(maxLoanAmountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              maxAmountAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (max) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loan Eligibility',
                        style: TextStyle(color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Up to ${Formatters.currency(max)}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Based on your MRI Score',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Request Loan',
                icon: Icons.add,
                onPressed: () => context.push('${AppRoutes.loans}/request'),
              ),
              const SizedBox(height: 24),
              Text('Active Loans', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...loans.map((loan) => _LoanCard(
                    loan: loan,
                    statusColor: _statusColor(loan.status),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends ConsumerStatefulWidget {
  const _LoanCard({required this.loan, required this.statusColor});

  final LoanEntity loan;
  final Color statusColor;

  @override
  ConsumerState<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends ConsumerState<_LoanCard> {
  void _showRepayDialog(BuildContext context) {
    final loan = widget.loan;
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Repay Loan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loan.groupName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Group: ${loan.groupName}'),
                ),
              Text('Remaining balance: ${Formatters.currency(loan.remainingBalance ?? 0)}'),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Amount (CFA)',
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
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
                      if (amount == null || amount <= 0) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(loanRepositoryProvider).repayLoan(
                              loanId: loan.id,
                              amount: amount,
                            );
                        ref.invalidate(loansProvider);
                        ref.invalidate(dashboardProvider);
                        ref.read(authStateProvider.notifier).refreshUser();
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
                  : const Text('Repay'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final statusColor = widget.statusColor;
    final progress = loan.status == LoanStatus.active && loan.remainingBalance != null
        ? 1 - (loan.remainingBalance! / loan.amount)
        : loan.status == LoanStatus.repaid
            ? 1.0
            : 0.0;

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
              Text(loan.purpose, style: Theme.of(context).textTheme.titleSmall),
              Text(
                loan.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(loan.amount),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (loan.groupName != null)
            Text(loan.groupName!, style: Theme.of(context).textTheme.bodySmall),
          if (loan.status == LoanStatus.active) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Remaining: ${Formatters.currency(loan.remainingBalance ?? 0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Repay',
              icon: Icons.payments_outlined,
              isOutlined: true,
              onPressed: () => _showRepayDialog(context),
            ),
          ],
        ],
      ),
    );
  }
}
