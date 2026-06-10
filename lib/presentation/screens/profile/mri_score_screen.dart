import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/mri_score_card.dart';

class MriScoreScreen extends ConsumerWidget {
  const MriScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MRI — Reliability Index')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dashboard) {
          final breakdown = dashboard.mriBreakdown;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MriScoreCard(
                  score: dashboard.mriScore,
                  trend: dashboard.mriTrend,
                ),
                const SizedBox(height: 24),
                if (breakdown != null) ...[
                  _BreakdownItem(
                    label: 'Payment Punctuality',
                    score: breakdown.paymentPunctuality,
                  ),
                  _BreakdownItem(
                    label: 'Attendance',
                    score: breakdown.attendance,
                  ),
                  _BreakdownItem(
                    label: 'Loan Repayment',
                    score: breakdown.loanRepayment,
                  ),
                  _BreakdownItem(
                    label: 'Contribution Consistency',
                    score: breakdown.contributionConsistency,
                  ),
                  _BreakdownItem(
                    label: 'Community Participation',
                    score: breakdown.communityParticipation,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                '${Formatters.mriScore(score)} / 10',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}
