import 'package:equatable/equatable.dart';

class MriEventEntity extends Equatable {
  const MriEventEntity({
    required this.delta,
    required this.reason,
    required this.description,
    required this.createdAt,
  });

  final double delta;
  final String reason;
  final String description;
  final DateTime createdAt;

  @override
  List<Object?> get props => [delta, reason, description, createdAt];
}

class MriHistoryEntity extends Equatable {
  const MriHistoryEntity({
    required this.mriScore,
    this.events = const [],
  });

  /// 0–10 decimal scale.
  final double mriScore;
  final List<MriEventEntity> events;

  @override
  List<Object?> get props => [mriScore, events];
}
