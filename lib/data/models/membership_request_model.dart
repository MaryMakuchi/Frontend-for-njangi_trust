import '../../core/utils/api_helper.dart';
import '../../domain/entities/membership_request_entity.dart';

class MembershipRequestModel {
  static MembershipRequestEntity fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return MembershipRequestEntity(
      id: json['id'].toString(),
      userId: user['id']?.toString() ?? '',
      userName: user['name'] as String? ?? '',
      requestedAt: parseDateTime(json['requested_at']) ?? DateTime.now(),
    );
  }
}
