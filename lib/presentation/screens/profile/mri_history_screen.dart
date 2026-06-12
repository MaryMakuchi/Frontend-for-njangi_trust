import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/mri_entity.dart';
import '../../providers/providers.dart';

/// Shows the user's current MRI score and a chronological list of MRI changes
/// (demerits/merits), so they understand why their reliability index moved.
class MriHistoryScreen extends ConsumerWidget {
  const MriHistoryScreen({super.key});

  static String _reasonLabel(String reason) {
    switch (reason) {
      case 'missed_contribution':
        return 'Missed contribution';
      case 'loan_default':
        return 'Loan default';
      case 'late_njangi':
        return 'Late njangi play';
      case 'membership_rejected':
        return 'Membership rejected';
      default:
        return reason
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mriHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MRI History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
        ),
        data: (history) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(mriHistoryProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ScoreHeader(score: history.mriScore),
              const SizedBox(height: 24),
              Text('Recent changes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (history.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No MRI changes yet — keep it up! 👍'),
                  ),
                )
              else
                ...history.events.map((e) => _MriEventTile(event: e)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Current MRI Score',
              style: TextStyle(color: AppColors.white)),
          const SizedBox(height: 8),
          Text(
            '${Formatters.mriScore(score)} / 10',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MriEventTile extends StatelessWidget {
  const _MriEventTile({required this.event});

  final MriEventEntity event;

  @override
  Widget build(BuildContext context) {
    final isNegative = event.delta < 0;
    final color = isNegative ? AppColors.error : AppColors.success;
    final sign = isNegative ? '' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isNegative ? Icons.trending_down : Icons.trending_up,
            color: color,
          ),
        ),
        title: Text(event.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(MriHistoryScreen._reasonLabel(event.reason)),
            Text(
              Formatters.dateTime(event.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          '$sign${event.delta.toStringAsFixed(1)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
