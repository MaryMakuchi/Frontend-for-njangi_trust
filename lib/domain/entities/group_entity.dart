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
    this.pickCycle,
  });

  final String id;
  final String name;
  final GroupRole role;
  final double mriScore;
  final bool isCurrentBeneficiary;
  final int? rotationPosition;
  final int? pickCycle;

  @override
  List<Object?> get props => [
        id,
        name,
        role,
        mriScore,
        isCurrentBeneficiary,
        rotationPosition,
        pickCycle,
      ];
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
    this.targetAmount,
    this.durationMonths = 12,
    this.pickingMode = 'random',
    this.scheduleGenerated = false,
    this.pickersPerCycle = 1,
    this.endDate,
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
  final double? targetAmount;
  final int durationMonths;
  final String pickingMode;
  final bool scheduleGenerated;
  final int pickersPerCycle;
  final DateTime? endDate;

  DateTime get effectiveEndDate =>
      endDate ?? DateTime(startDate.year, startDate.month + durationMonths, startDate.day);

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
        targetAmount,
        durationMonths,
        pickingMode,
        scheduleGenerated,
        pickersPerCycle,
        endDate,
      ];
}
