import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionEntity transaction;

  IconData get _icon {
    switch (transaction.type) {
      case TransactionType.contribution:
        return Icons.savings_outlined;
      case TransactionType.payout:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.loanDisbursement:
        return Icons.trending_up;
      case TransactionType.loanRepayment:
        return Icons.payments_outlined;
      case TransactionType.socialFund:
        return Icons.favorite_outline;
      case TransactionType.walletTopup:
      case TransactionType.walletWithdrawal:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.savingsDeposit:
      case TransactionType.savingsWithdrawal:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final prefix = isCredit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppColors.purple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formatters.date(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '$prefix${Formatters.currency(transaction.amount)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
