import 'package:equatable/equatable.dart';

enum GroupRole { president, vicePresident, treasurer, secretary, auditor, member }

class GroupMemberEntity extends Equatable {
  const GroupMemberEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.mriScore,
    this.slotName = '',
    this.isCurrentBeneficiary = false,
    this.rotationPosition,
    this.pickCycle,
  });

  final String id;
  final String name;
  final String slotName;
  final GroupRole role;
  final double mriScore;
  final bool isCurrentBeneficiary;
  final int? rotationPosition;
  final int? pickCycle;

  @override
  List<Object?> get props => [
        id,
        name,
        slotName,
        role,
        mriScore,
        isCurrentBeneficiary,
        rotationPosition,
        pickCycle,
      ];
}

class ElectionNomineeEntity extends Equatable {
  const ElectionNomineeEntity({
    required this.nomineeId,
    required this.nomineeName,
    required this.nominationCount,
  });

  final String nomineeId;
  final String nomineeName;
  final int nominationCount;

  @override
  List<Object?> get props => [nomineeId, nomineeName, nominationCount];
}

class ElectionEntity extends Equatable {
  const ElectionEntity({
    required this.id,
    required this.status,
    this.createdAt,
    this.nominations = const {},
    this.myVotes = const {},
  });

  final String id;
  final String status; // 'nominations' | 'voting' | 'complete'
  final DateTime? createdAt;
  final Map<String, List<ElectionNomineeEntity>> nominations;
  final Map<String, String> myVotes; // role -> nomineeId

  @override
  List<Object?> get props => [id, status, createdAt, nominations, myVotes];
}

class UserSearchResultEntity extends Equatable {
  const UserSearchResultEntity({
    required this.id,
    required this.username,
    required this.name,
  });

  final String id;
  final String username;
  final String name;

  @override
  List<Object?> get props => [id, username, name];
}

class GroupSlotEntity extends Equatable {
  const GroupSlotEntity({
    required this.membershipId,
    required this.slotName,
    required this.role,
    this.rotationPosition,
    this.isCurrentBeneficiary = false,
    required this.joinedAt,
  });

  final String membershipId;
  final String slotName;
  final String role;
  final int? rotationPosition;
  final bool isCurrentBeneficiary;
  final DateTime joinedAt;

  @override
  List<Object?> get props => [membershipId, slotName, role, rotationPosition, isCurrentBeneficiary, joinedAt];
}

class CurrentPickerEntity extends Equatable {
  const CurrentPickerEntity({
    required this.id,
    required this.name,
    this.rotationPosition,
  });

  final String id;
  final String name;
  final int? rotationPosition;

  @override
  List<Object?> get props => [id, name, rotationPosition];
}

class PlayNjangiPayoutEntity extends Equatable {
  const PlayNjangiPayoutEntity({
    required this.amount,
    required this.recipientId,
    required this.recipientName,
    this.transactionHash,
  });

  final double amount;
  final String recipientId;
  final String recipientName;
  final String? transactionHash;

  @override
  List<Object?> get props => [amount, recipientId, recipientName, transactionHash];
}

class PlayNjangiResultEntity extends Equatable {
  const PlayNjangiResultEntity({
    required this.amount,
    required this.groupFundBalance,
    required this.cycleProgress,
    required this.maxMembers,
    this.currentPicker,
    this.cycleCompleted = false,
    this.payout,
  });

  final double amount;
  final double groupFundBalance;
  final int cycleProgress;
  final int maxMembers;
  final CurrentPickerEntity? currentPicker;
  final bool cycleCompleted;
  final PlayNjangiPayoutEntity? payout;

  @override
  List<Object?> get props => [
        amount,
        groupFundBalance,
        cycleProgress,
        maxMembers,
        currentPicker,
        cycleCompleted,
        payout,
      ];
}

class GroupSearchResultEntity extends Equatable {
  const GroupSearchResultEntity({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.maxMembers,
  });

  final String id;
  final String name;
  final int memberCount;
  final int maxMembers;

  @override
  List<Object?> get props => [id, name, memberCount, maxMembers];
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
    this.currentPicker,
    this.rotationStarted = false,
    this.playFrequency,
    this.playWeekday,
    this.playWeekOfMonth,
    this.playDeadlineTime,
    this.nextPlayDue,
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
  final CurrentPickerEntity? currentPicker;
  final bool rotationStarted;
  final String? playFrequency;
  final int? playWeekday;
  final String? playWeekOfMonth;
  final String? playDeadlineTime;
  final DateTime? nextPlayDue;

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
        currentPicker,
        rotationStarted,
        playFrequency,
        playWeekday,
        playWeekOfMonth,
        playDeadlineTime,
        nextPlayDue,
      ];
}
