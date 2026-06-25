import '../entities/contribution_entity.dart';
import '../entities/transaction_entity.dart';

abstract class ContributionRepository {
  Future<List<ContributionEntity>> getContributions();
  Future<TransactionEntity> makeContribution({
    required String groupId,
    required double amount,
    required String paymentMethod,
    String? linkedAccountId,
  });
}
