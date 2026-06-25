import '../entities/balance_update_entity.dart';
import '../entities/linked_account_entity.dart';

abstract class WalletRepository {
  Future<List<LinkedAccountEntity>> getLinkedAccounts();
  Future<LinkedAccountEntity> addLinkedAccount({
    required LinkedAccountType accountType,
    required String provider,
    required String accountNumber,
    required String accountName,
    bool isDefault = false,
  });
  Future<void> deleteLinkedAccount(String id);
  Future<BalanceUpdateEntity> topUpWallet(double amount, {String? linkedAccountId});
  Future<BalanceUpdateEntity> withdrawWallet({required double amount, required String linkedAccountId});
  Future<BalanceUpdateEntity> depositToSavings(double amount);
  Future<BalanceUpdateEntity> withdrawFromSavings(double amount);
}
