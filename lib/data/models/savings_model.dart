import '../../core/utils/api_helper.dart';
import '../../domain/entities/savings_entity.dart';

class SavingsPeriodModel {
  static SavingsPeriodEntity fromJson(Map<String, dynamic> json) {
    return SavingsPeriodEntity(
      id: json['id'].toString(),
      interestRate: parseDouble(json['interest_rate']),
      interestType: json['interest_type'] as String? ?? 'simple',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: json['status'] as String? ?? '',
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }
}

class SavingsDepositModel {
  static SavingsDepositEntity fromJson(Map<String, dynamic> json) {
    return SavingsDepositEntity(
      amount: parseDouble(json['amount']),
      date: parseDate(json['date']),
    );
  }
}

class SavingsSummaryModel {
  static SavingsSummaryEntity fromJson(Map<String, dynamic> json) {
    final depositsJson = json['deposits'] as List? ?? [];
    return SavingsSummaryEntity(
      principal: parseDouble(json['principal']),
      interestAccrued: parseDouble(json['interest_accrued']),
      total: parseDouble(json['total']),
      deposits: depositsJson
          .map((d) => SavingsDepositModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroupSavingsModel {
  static GroupSavingsEntity fromJson(Map<String, dynamic> json) {
    final periodJson = json['period'];
    final mySavingsJson = json['my_savings'];
    return GroupSavingsEntity(
      period: periodJson is Map<String, dynamic>
          ? SavingsPeriodModel.fromJson(periodJson)
          : null,
      mySavings: mySavingsJson is Map<String, dynamic>
          ? SavingsSummaryModel.fromJson(mySavingsJson)
          : null,
    );
  }
}

class SavingsWithdrawalResultModel {
  static SavingsWithdrawalResultEntity fromJson(Map<String, dynamic> json) {
    return SavingsWithdrawalResultEntity(
      amountWithdrawn: parseDouble(json['amount_withdrawn']),
      newWalletBalance: parseDouble(json['new_wallet_balance']),
    );
  }
}
