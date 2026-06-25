import 'package:equatable/equatable.dart';

class MembershipRequestEntity extends Equatable {
  const MembershipRequestEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.requestedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final DateTime requestedAt;

  @override
  List<Object?> get props => [id, userId, userName, requestedAt];
}
