import 'package:equatable/equatable.dart';

enum ContributionStatus { pending, completed, late, outstanding }

class ContributionEntity extends Equatable {
  const ContributionEntity({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
    this.paymentMethod,
  });

  final String id;
  final String groupId;
  final String groupName;
  final double amount;
  final DateTime dueDate;
  final ContributionStatus status;
  final DateTime? paidDate;
  final String? paymentMethod;

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        amount,
        dueDate,
        status,
        paidDate,
        paymentMethod,
      ];
}
