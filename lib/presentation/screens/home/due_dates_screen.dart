import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/njangi_hype.dart';
import '../../../domain/entities/due_date_entity.dart';
import '../../providers/providers.dart';

/// Visual metadata (color + icon) for a due-date [type].
({Color color, IconData icon}) dueDateTypeStyle(String type) {
  switch (type) {
    case 'njangi':
      return (color: AppColors.purple, icon: Icons.casino_outlined);
    case 'social_fund':
      return (color: AppColors.orchid, icon: Icons.favorite_outline);
    case 'loan_repayment':
      return (color: AppColors.info, icon: Icons.account_balance_outlined);
    default:
      return (color: AppColors.primary, icon: Icons.event);
  }
}

const Map<String, String> _horizonLabels = {
  '3m': '3 months',
  '6m': '6 months',
  '12m': '12 months',
  'all': 'All',
};

class DueDatesScreen extends ConsumerStatefulWidget {
  const DueDatesScreen({super.key});

  @override
  ConsumerState<DueDatesScreen> createState() => _DueDatesScreenState();
}

class _DueDatesScreenState extends ConsumerState<DueDatesScreen> {
  String _horizon = '3m';

  @override
  Widget build(BuildContext context) {
    final dueDatesAsync = ref.watch(dueDatesProvider(_horizon));

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Due Dates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: _horizonLabels.entries
                    .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                    .toList(),
                selected: {_horizon},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _horizon = s.first),
              ),
            ),
          ),
          Expanded(
            child: dueDatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (dues) {
                if (dues.isEmpty) {
                  return const Center(
                    child: Text('No upcoming dues 🎉'),
                  );
                }
                final sorted = [...dues]
                  ..sort((a, b) => a.dueDatetime.compareTo(b.dueDatetime));
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      DueDateTile(due: sorted[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DueDateTile extends StatelessWidget {
  const DueDateTile({super.key, required this.due});

  final DueDateEntity due;

  @override
  Widget build(BuildContext context) {
    final style = dueDateTypeStyle(due.type);
    final isOverdue = due.dueDatetime.isBefore(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDueDateTime(due.dueDatetime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  relativeDueLabel(due.dueDatetime),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isOverdue ? AppColors.error : style.color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (due.amount != null) ...[
            const SizedBox(width: 8),
            Text(
              Formatters.currency(due.amount!),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
