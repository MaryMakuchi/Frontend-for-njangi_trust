import '../../core/utils/api_helper.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  static NotificationEntity fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'].toString(),
      title: json['title'] as String,
      body: json['body'] as String,
      type: _parseType(json['type'] as String?),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id']?.toString() ?? '',
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'loan_approval':
        return NotificationType.loanApproval;
      case 'contribution_confirmation':
        return NotificationType.contributionConfirmation;
      case 'upcoming_payout':
        return NotificationType.upcomingPayout;
      case 'group_announcement':
        return NotificationType.groupAnnouncement;
      default:
        return NotificationType.paymentReminder;
    }
  }
}
