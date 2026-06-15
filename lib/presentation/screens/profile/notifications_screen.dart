import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';

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
      case NotificationType.mriUpdate:
        return Icons.trending_down;
      case NotificationType.membershipRequest:
        return Icons.person_add_alt_1_outlined;
    }
  }

  void _navigateToTarget(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity n,
  ) {
    switch (n.targetType) {
      case 'group':
        // Only open the group screen if the user is actually a member — a
        // rejected/declined membership notification points at a group they
        // can't view, which would otherwise crash the details screen. In that
        // case (and any other), fall back to the dashboard for good UX.
        final groups = ref.read(groupsProvider).valueOrNull ?? const [];
        final isMember =
            n.targetId.isNotEmpty && groups.any((g) => g.id == n.targetId);
        if (isMember) {
          // Deep-link into a specific tab (e.g. Members) when the notification
          // names one, otherwise open the group at its default tab.
          final tabQuery =
              n.targetView.isNotEmpty ? '?tab=${n.targetView}' : '';
          context.push('${AppRoutes.groups}/${n.targetId}$tabQuery');
        } else {
          context.go(AppRoutes.home);
        }
        break;
      case 'loan':
        context.push(AppRoutes.loans);
        break;
      case 'transaction':
        context.push(AppRoutes.blockchainLedger);
        break;
      default:
        // Anything without a navigable target returns to the dashboard rather
        // than leaving the tap doing nothing.
        context.go(AppRoutes.home);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Read All'),
          ),
        ],
      ),
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
                ref.invalidate(unreadNotificationCountProvider);
                _navigateToTarget(context, ref, n);
              },
            );
          },
        ),
      ),
    );
  }
}
