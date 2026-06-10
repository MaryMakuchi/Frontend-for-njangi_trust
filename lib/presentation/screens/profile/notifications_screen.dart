import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.paymentReminder:
        return Icons.alarm;
      case NotificationType.loanApproval:
        return Icons.check_circle_outline;
      case NotificationType.contributionConfirmation:
        return Icons.payment;
      case NotificationType.upcomingPayout:
        return Icons.event;
      case NotificationType.groupAnnouncement:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final n = notifications[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: n.isRead
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  _iconFor(n.type),
                  color: n.isRead ? AppColors.mediumGray : AppColors.primary,
                ),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.body),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dateTime(n.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                ref.read(notificationRepositoryProvider).markAsRead(n.id);
                ref.invalidate(notificationsProvider);
              },
            );
          },
        ),
      ),
    );
  }
}
