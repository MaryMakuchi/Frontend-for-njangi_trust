import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'balance_text.dart';

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.amount,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// When provided, the value is rendered with [BalanceText] so it can be
  /// hidden/shown via the shared balance-visibility toggle. [value] is
  /// ignored in this case.
  final double? amount;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 11,
                    height: 1.1,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: amount != null
                  ? BalanceText(
                      amount!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.1,
                            color: AppColors.darkGray,
                          ),
                      iconColor: AppColors.mediumGray,
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.1,
                            color: AppColors.darkGray,
                          ),
                      maxLines: 1,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
