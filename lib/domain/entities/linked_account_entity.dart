import 'package:equatable/equatable.dart';

enum LinkedAccountType { mobileMoney, bank }

class LinkedAccountEntity extends Equatable {
  const LinkedAccountEntity({
    required this.id,
    required this.accountType,
    required this.provider,
    required this.accountNumber,
    required this.accountName,
    this.isDefault = false,
  });

  final String id;
  final LinkedAccountType accountType;
  final String provider;
  final String accountNumber;
  final String accountName;
  final bool isDefault;

  @override
  List<Object?> get props =>
      [id, accountType, provider, accountNumber, accountName, isDefault];
}
