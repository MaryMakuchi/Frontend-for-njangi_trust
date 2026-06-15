import '../../core/utils/api_helper.dart';
import '../../domain/entities/reconciliation_entity.dart';

class ReconciliationModel {
  static ReconMemberEntity _member(Map<String, dynamic> json) {
    return ReconMemberEntity(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      hasPaid: json['has_paid'] as bool? ?? false,
      amountPaid: parseDouble(json['amount_paid']),
    );
  }

  static ReconciliationEntity fromJson(Map<String, dynamic> json) {
    final cycle = json['cycle'] as Map<String, dynamic>? ?? const {};
    final lifetime = json['lifetime'] as Map<String, dynamic>? ?? const {};
    final members = (json['members'] as List? ?? const [])
        .map((e) => _member(e as Map<String, dynamic>))
        .toList();
    final unpaid = (json['unpaid_members'] as List? ?? const [])
        .map((e) => _member(e as Map<String, dynamic>))
        .toList();

    return ReconciliationEntity(
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name'] as String? ?? '',
      contributionAmount: parseDouble(json['contribution_amount']),
      activeMembers: parseInt(json['active_members']),
      maxMembers: parseInt(json['max_members']),
      isPresident: json['is_president'] as bool? ?? false,
      expected: parseDouble(cycle['expected']),
      collected: parseDouble(cycle['collected']),
      outstanding: parseDouble(cycle['outstanding']),
      paidCount: parseInt(cycle['paid_count']),
      status: cycle['status'] as String? ?? 'on_track',
      totalCollected: parseDouble(lifetime['total_collected']),
      totalPaidOut: parseDouble(lifetime['total_paid_out']),
      loansOutstanding: parseDouble(lifetime['loans_outstanding']),
      fundBalance: parseDouble(lifetime['fund_balance']),
      members: members,
      unpaidMembers: unpaid,
    );
  }
}
