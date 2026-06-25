import 'package:equatable/equatable.dart';

class GroupMessageEntity extends Equatable {
  const GroupMessageEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, groupId, userId, userName, message, createdAt];
}
