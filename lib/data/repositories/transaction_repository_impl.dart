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
  Future<List<TransactionEntity>> getTransactions({String? status}) async {
    if (AppConstants.useMockData) {
      var list = MockData.transactions;
      if (status != null) {
        list = list.where((t) => t.status.name == status).toList();
      }
      return list;
    }

    var path = '/transactions/';
    if (status != null) path += '?status=$status';

    final response = await _api.get(path);
    return parseListResponse(response)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
