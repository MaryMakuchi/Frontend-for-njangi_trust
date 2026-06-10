import 'package:equatable/equatable.dart';

enum GroupRole { president, treasurer, member }

class GroupMemberEntity extends Equatable {
  const GroupMemberEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.mriScore,
    this.isCurrentBeneficiary = false,
    this.rotationPosition,
  });

  final String id;
  final String name;
  final GroupRole role;
  final double mriScore;
  final bool isCurrentBeneficiary;
  final int? rotationPosition;

  @override
  List<Object?> get props =>
      [id, name, role, mriScore, isCurrentBeneficiary, rotationPosition];
}

class GroupEntity extends Equatable {
  const GroupEntity({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.maxMembers,
    required this.contributionAmount,
    required this.frequency,
    required this.fundBalance,
    required this.cycleProgress,
    required this.averageMri,
    required this.startDate,
    this.invitationCode,
    this.rules,
    this.members = const [],
    this.currentBeneficiaryId,
    this.nextBeneficiaryId,
  });

  final String id;
  final String name;
  final int memberCount;
  final int maxMembers;
  final double contributionAmount;
  final String frequency;
  final double fundBalance;
  final int cycleProgress;
  final double averageMri;
  final DateTime startDate;
  final String? invitationCode;
  final String? rules;
  final List<GroupMemberEntity> members;
  final String? currentBeneficiaryId;
  final String? nextBeneficiaryId;

  @override
  List<Object?> get props => [
        id,
        name,
        memberCount,
        maxMembers,
        contributionAmount,
        frequency,
        fundBalance,
        cycleProgress,
        averageMri,
        startDate,
        invitationCode,
        rules,
        members,
        currentBeneficiaryId,
        nextBeneficiaryId,
      ];
}
