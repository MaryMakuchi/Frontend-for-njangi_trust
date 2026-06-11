import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';

class BlockchainLedgerScreen extends ConsumerWidget {
  const BlockchainLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blockchain Ledger')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = transactions[i];
            return Container(
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
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t.onChain
                              ? AppColors.successLight
                              : AppColors.mediumGray.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              t.onChain ? Icons.verified : Icons.hourglass_top,
                              size: 14,
                              color: t.onChain ? AppColors.success : AppColors.mediumGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.onChain ? 'On-chain' : 'Recorded',
                              style: TextStyle(
                                color: t.onChain ? AppColors.success : AppColors.mediumGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t.isCredit ? '+' : '-'}${Formatters.currency(t.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: t.isCredit ? AppColors.success : AppColors.error,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dateTime(t.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (t.hash != null && t.hash!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: t.explorerUrl != null
                          ? () => launchUrl(
                                Uri.parse(t.explorerUrl!),
                                mode: LaunchMode.externalApplication,
                              )
                          : null,
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 14, color: AppColors.purple),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.hash!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.purple,
                                    decoration: t.explorerUrl != null
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.explorerUrl != null)
                            const Icon(Icons.open_in_new, size: 14, color: AppColors.purple),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
