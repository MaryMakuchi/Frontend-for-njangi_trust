import '../../domain/entities/linked_account_entity.dart';

class LinkedAccountModel {
  static LinkedAccountEntity fromJson(Map<String, dynamic> json) {
    return LinkedAccountEntity(
      id: json['id'].toString(),
      accountType: _parseType(json['account_type'] as String?),
      provider: json['provider'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static LinkedAccountType _parseType(String? type) {
    switch (type) {
      case 'bank':
        return LinkedAccountType.bank;
      default:
        return LinkedAccountType.mobileMoney;
    }
  }

  static String typeToJson(LinkedAccountType type) {
    switch (type) {
      case LinkedAccountType.bank:
        return 'bank';
      case LinkedAccountType.mobileMoney:
        return 'mobile_money';
    }
  }
}
