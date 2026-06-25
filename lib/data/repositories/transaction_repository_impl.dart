import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/mock_data.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<TransactionEntity>> getTransactions({String? status, String? type}) async {
    if (AppConstants.useMockData) {
      var list = MockData.transactions;
      if (status != null) {
        list = list.where((t) => t.status.name == status).toList();
      }
      if (type != null) {
        final types = type.split(',');
        list = list.where((t) => types.contains(_typeKey(t.type))).toList();
      }
      return list;
    }

    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (type != null) params.add('type=$type');
    var path = '/transactions/';
    if (params.isNotEmpty) path += '?${params.join('&')}';

    final response = await _api.get(path);
    return parseListResponse(response)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _typeKey(TransactionType type) {
    switch (type) {
      case TransactionType.contribution:
        return 'contribution';
      case TransactionType.payout:
        return 'payout';
      case TransactionType.loanDisbursement:
        return 'loan_disbursement';
      case TransactionType.loanRepayment:
        return 'loan_repayment';
      case TransactionType.socialFund:
        return 'social_fund';
      case TransactionType.walletTopup:
        return 'wallet_topup';
      case TransactionType.walletWithdrawal:
        return 'wallet_withdrawal';
      case TransactionType.savingsDeposit:
        return 'savings_deposit';
      case TransactionType.savingsWithdrawal:
        return 'savings_withdrawal';
    }
  }
}
