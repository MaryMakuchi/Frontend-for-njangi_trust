import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../providers/providers.dart';

const _demoPin = '1234';

class BalanceText extends ConsumerWidget {
  const BalanceText(
    this.amount, {
    super.key,
    this.style,
    this.iconColor,
  });

  final double amount;
  final TextStyle? style;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(balanceVisibleProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isVisible ? Formatters.currency(amount) : '••••••',
          style: style,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            if (isVisible) {
              ref.read(balanceVisibleProvider.notifier).set(false);
              return;
            }
            final unlocked = await _showPinDialog(context);
            if (unlocked) {
              ref.read(balanceVisibleProvider.notifier).set(true);
            }
          },
          child: Icon(
            isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: iconColor ?? style?.color ?? AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Future<bool> _showPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Enter PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your 4-digit PIN to view your balance.'),
              const SizedBox(height: 16),
              PinCodeTextField(
                appContext: dialogContext,
                length: AppConstants.pinLength,
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 48,
                  fieldWidth: 48,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
                onChanged: (_) {},
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (pinController.text == _demoPin) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  setState(() => error = 'Incorrect PIN. Try again.');
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }
}
