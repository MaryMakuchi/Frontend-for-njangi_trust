import 'package:equatable/equatable.dart';

class DueDateEntity extends Equatable {
  const DueDateEntity({
    required this.type,
    required this.label,
    required this.groupId,
    required this.dueDatetime,
    this.groupName,
    this.amount,
  });

  /// "njangi" | "social_fund" | "loan_repayment"
  final String type;
  final String label;
  final String groupId;
  final String? groupName;
  final double? amount;
  final DateTime dueDatetime;

  @override
  List<Object?> get props => [type, label, groupId, groupName, amount, dueDatetime];
}
