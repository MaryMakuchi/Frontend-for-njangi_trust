import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/contribution_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/contribution_repository.dart';
import '../datasources/mock_data.dart';
import '../models/contribution_model.dart';
import '../models/transaction_model.dart';

class ContributionRepositoryImpl implements ContributionRepository {
  ContributionRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<ContributionEntity>> getContributions() async {
    if (AppConstants.useMockData) return MockData.contributions;

    final response = await _api.get('/contributions/');
    return parseListResponse(response)
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TransactionEntity> makeContribution({
    required String groupId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (AppConstants.useMockData) {
      final group = MockData.groups.firstWhere((g) => g.id == groupId);
      return TransactionEntity(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Contribution - ${group.name}',
        amount: amount,
        type: TransactionType.contribution,
        status: TransactionStatus.verified,
        date: DateTime.now(),
        groupName: group.name,
        hash: '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        isCredit: false,
      );
    }

    final response = await _api.post(
      '/contributions/pay/',
      body: {
        'group_id': groupId,
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );
    return TransactionModel.fromJson(parseJsonResponse(response));
  }
}
