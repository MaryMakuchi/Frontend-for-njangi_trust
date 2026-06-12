import 'package:equatable/equatable.dart';

class GroupPreviewEntity extends Equatable {
  const GroupPreviewEntity({
    required this.id,
    required this.name,
    required this.contributionAmount,
    required this.maxMembers,
    required this.memberCount,
    required this.isMember,
    required this.hasPendingRequest,
    this.rules,
    this.playFrequency,
    this.nextPlayDue,
    this.presidentName,
  });

  final String id;
  final String name;
  final String? rules;
  final double contributionAmount;
  final int maxMembers;
  final int memberCount;
  final String? playFrequency;
  final DateTime? nextPlayDue;
  final String? presidentName;
  final bool isMember;
  final bool hasPendingRequest;

  @override
  List<Object?> get props => [
        id,
        name,
        rules,
        contributionAmount,
        maxMembers,
        memberCount,
        playFrequency,
        nextPlayDue,
        presidentName,
        isMember,
        hasPendingRequest,
      ];
}
