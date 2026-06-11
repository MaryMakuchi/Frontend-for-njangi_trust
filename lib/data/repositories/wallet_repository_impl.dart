import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/balance_update_entity.dart';
import '../../domain/entities/linked_account_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/linked_account_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<LinkedAccountEntity>> getLinkedAccounts() async {
    if (AppConstants.useMockData) return [];

    final response = await _api.get('/accounts/linked/');
    return parseListResponse(response)
        .map((e) => LinkedAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LinkedAccountEntity> addLinkedAccount({
    required LinkedAccountType accountType,
    required String provider,
    required String accountNumber,
    required String accountName,
    bool isDefault = false,
  }) async {
    if (AppConstants.useMockData) {
      return LinkedAccountEntity(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        accountType: accountType,
        provider: provider,
        accountNumber: accountNumber,
        accountName: accountName,
        isDefault: isDefault,
      );
    }

    final response = await _api.post(
      '/accounts/linked/',
      body: {
        'account_type': LinkedAccountModel.typeToJson(accountType),
        'provider': provider,
        'account_number': accountNumber,
        'account_name': accountName,
        'is_default': isDefault,
      },
    );
    return LinkedAccountModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<void> deleteLinkedAccount(String id) async {
    if (AppConstants.useMockData) return;
    await _api.delete('/accounts/linked/$id/');
  }

  @override
  Future<BalanceUpdateEntity> topUpWallet(double amount) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError('Wallet top-up is not available in mock mode');
    }
    final response = await _api.post('/wallet/topup/', body: {'amount': amount});
    return _parseBalances(parseJsonResponse(response));
  }

  @override
  Future<BalanceUpdateEntity> withdrawWallet({
    required double amount,
    required String linkedAccountId,
  }) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError('Wallet withdrawal is not available in mock mode');
    }
    final response = await _api.post(
      '/wallet/withdraw/',
      body: {'amount': amount, 'linked_account_id': linkedAccountId},
    );
    return _parseBalances(parseJsonResponse(response));
  }

  @override
  Future<BalanceUpdateEntity> depositToSavings(double amount) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError('Savings deposit is not available in mock mode');
    }
    final response = await _api.post('/savings/deposit/', body: {'amount': amount});
    return _parseBalances(parseJsonResponse(response));
  }

  @override
  Future<BalanceUpdateEntity> withdrawFromSavings(double amount) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError('Savings withdrawal is not available in mock mode');
    }
    final response = await _api.post('/savings/withdraw/', body: {'amount': amount});
    return _parseBalances(parseJsonResponse(response));
  }

  BalanceUpdateEntity _parseBalances(Map<String, dynamic> json) {
    return BalanceUpdateEntity(
      walletBalance: json['wallet_balance'] != null ? parseDouble(json['wallet_balance']) : null,
      savingsBalance: json['savings_balance'] != null ? parseDouble(json['savings_balance']) : null,
    );
  }
}
