import 'package:equatable/equatable.dart';

enum NotificationType {
  paymentReminder,
  loanApproval,
  contributionConfirmation,
  upcomingPayout,
  groupAnnouncement,
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.targetType = '',
    this.targetId = '',
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String targetType;
  final String targetId;

  @override
  List<Object?> get props =>
      [id, title, body, type, createdAt, isRead, targetType, targetId];
}
