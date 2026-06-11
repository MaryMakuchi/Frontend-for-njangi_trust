import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../data/datasources/mock_data.dart';
import '../../providers/providers.dart';
import '../../widgets/balance_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/transaction_tile.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final historyAsync = ref.watch(savingsHistoryProvider);
    final chartData = MockData.savingsChartData;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Overview')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(savingsHistoryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
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
                      const Text(
                        'Total Savings',
                        style: TextStyle(color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      BalanceText(
                        dashboard.savingsBalance,
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
                          const Text('Wallet Balance: ', style: TextStyle(color: AppColors.white)),
                          BalanceText(
                            dashboard.walletBalance,
                            style: const TextStyle(color: AppColors.white),
                            iconColor: AppColors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Save',
                        icon: Icons.south_west,
                        onPressed: () => _showSaveSourceDialog(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: 'Withdraw to Wallet',
                        icon: Icons.north_east,
                        isOutlined: true,
                        onPressed: () => _showAmountDialog(
                          context,
                          ref,
                          title: 'Withdraw from Savings',
                          confirmLabel: 'Withdraw',
                          onConfirm: (amount) => ref
                              .read(walletRepositoryProvider)
                              .withdrawFromSavings(amount),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Growth', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: const [
                    _ChartLegend(color: AppColors.primary, label: 'Overall Balance'),
                    _ChartLegend(color: AppColors.success, label: 'Deposits'),
                    _ChartLegend(color: AppColors.error, label: 'Withdrawals'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= chartData.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                chartData[i]['month'] as String,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        _buildLine(chartData, 'balance', AppColors.primary, filled: true),
                        _buildLine(chartData, 'deposits', AppColors.success),
                        _buildLine(chartData, 'withdrawals', AppColors.error),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Deposits & Withdrawals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (history) {
                    if (history.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No savings activity yet.'),
                      );
                    }
                    return Column(
                      children:
                          history.map((t) => TransactionTile(transaction: t)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLine(
    List<Map<String, dynamic>> data,
    String key,
    Color color, {
    bool filled = false,
  }) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        return FlSpot(
          e.key.toDouble(),
          (e.value[key] as double) / 1000000,
        );
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: filled,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  void _showSaveSourceDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save from', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            _SaveSourceTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showAmountDialog(
                  context,
                  ref,
                  title: 'Save from Wallet',
                  confirmLabel: 'Save',
                  onConfirm: (amount) =>
                      ref.read(walletRepositoryProvider).depositToSavings(amount),
                );
              },
            ),
            _SaveSourceTile(
              icon: Icons.phone_android,
              label: 'Mobile Money',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showAmountDialog(
                  context,
                  ref,
                  title: 'Save from Mobile Money',
                  confirmLabel: 'Save',
                  onConfirm: (amount) =>
                      ref.read(walletRepositoryProvider).depositToSavings(amount),
                );
              },
            ),
            _SaveSourceTile(
              icon: Icons.account_balance_outlined,
              label: 'Bank Account',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showAmountDialog(
                  context,
                  ref,
                  title: 'Save from Bank Account',
                  confirmLabel: 'Save',
                  onConfirm: (amount) =>
                      ref.read(walletRepositoryProvider).depositToSavings(amount),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String confirmLabel,
    required Future<void> Function(double amount) onConfirm,
  }) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(title),
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
                        await onConfirm(amount);
                        ref.invalidate(dashboardProvider);
                        ref.invalidate(savingsHistoryProvider);
                        ref.read(authStateProvider.notifier).refreshUser();
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
                  : Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SaveSourceTile extends StatelessWidget {
  const _SaveSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.purpleSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.purple),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
