import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/contribution_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';

class ContributionScreen extends ConsumerWidget {
  const ContributionScreen({super.key});

  Color _statusColor(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.completed:
        return AppColors.success;
      case ContributionStatus.late:
        return AppColors.error;
      case ContributionStatus.outstanding:
        return AppColors.warning;
      case ContributionStatus.pending:
        return AppColors.info;
    }
  }

  String _statusLabel(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.completed:
        return 'Completed';
      case ContributionStatus.late:
        return 'Late';
      case ContributionStatus.outstanding:
        return 'Outstanding';
      case ContributionStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(contributionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.contributions}/pay'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.payment, color: AppColors.white),
        label: const Text('Pay', style: TextStyle(color: AppColors.white)),
      ),
      body: contributionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contributions) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(contributionsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CustomButton(
                label: 'Make Contribution',
                icon: Icons.payment,
                onPressed: () => context.push('${AppRoutes.contributions}/pay'),
              ),
              const SizedBox(height: 24),
              Text(
                'Contribution History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...contributions.map((c) => _ContributionCard(
                    contribution: c,
                    statusColor: _statusColor(c.status),
                    statusLabel: _statusLabel(c.status),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.contribution,
    required this.statusColor,
    required this.statusLabel,
  });

  final ContributionEntity contribution;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
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
              Text(
                contribution.groupName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(contribution.amount),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            AppDateUtils.relativeDue(contribution.dueDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (contribution.paidDate != null)
            Text(
              'Paid: ${Formatters.date(contribution.paidDate!)} via ${contribution.paymentMethod}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
