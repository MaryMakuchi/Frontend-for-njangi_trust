import 'package:equatable/equatable.dart';

/// One member's payment status for the current cycle.
class ReconMemberEntity extends Equatable {
  const ReconMemberEntity({
    required this.userId,
    required this.name,
    required this.role,
    required this.hasPaid,
    required this.amountPaid,
  });

  final String userId;
  final String name;
  final String role;
  final bool hasPaid;
  final double amountPaid;

  @override
  List<Object?> get props => [userId, name, role, hasPaid, amountPaid];
}

/// Treasurer-liability reconciliation for a group: expected vs collected vs
/// paid out for the current cycle, plus running lifetime totals.
class ReconciliationEntity extends Equatable {
  const ReconciliationEntity({
    required this.groupId,
    required this.groupName,
    required this.contributionAmount,
    required this.activeMembers,
    required this.maxMembers,
    required this.isPresident,
    required this.expected,
    required this.collected,
    required this.outstanding,
    required this.paidCount,
    required this.status,
    required this.totalCollected,
    required this.totalPaidOut,
    required this.loansOutstanding,
    required this.fundBalance,
    required this.members,
    required this.unpaidMembers,
  });

  final String groupId;
  final String groupName;
  final double contributionAmount;
  final int activeMembers;
  final int maxMembers;
  final bool isPresident;

  // Current-cycle figures.
  final double expected;
  final double collected;
  final double outstanding;
  final int paidCount;

  /// 'on_track' | 'shortfall' | 'surplus'
  final String status;

  // Lifetime running totals.
  final double totalCollected;
  final double totalPaidOut;
  final double loansOutstanding;
  final double fundBalance;

  final List<ReconMemberEntity> members;
  final List<ReconMemberEntity> unpaidMembers;

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        contributionAmount,
        activeMembers,
        maxMembers,
        isPresident,
        expected,
        collected,
        outstanding,
        paidCount,
        status,
        totalCollected,
        totalPaidOut,
        loansOutstanding,
        fundBalance,
        members,
        unpaidMembers,
      ];
}
