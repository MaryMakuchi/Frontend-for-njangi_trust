import '../../core/utils/api_helper.dart';
import '../../domain/entities/mri_entity.dart';

class MriEventModel {
  static MriEventEntity fromJson(Map<String, dynamic> json) {
    return MriEventEntity(
      delta: parseDouble(json['delta']),
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }
}

class MriHistoryModel {
  static MriHistoryEntity fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List? ?? [];
    return MriHistoryEntity(
      mriScore: parseDouble(json['mri_score']),
      events: eventsJson
          .map((e) => MriEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
