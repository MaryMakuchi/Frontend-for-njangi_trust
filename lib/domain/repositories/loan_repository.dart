import '../entities/loan_entity.dart';

abstract class LoanRepository {
  Future<List<LoanEntity>> getLoans();
  Future<double> getMaxEligibleAmount();
  Future<LoanEntity> requestLoan({
    required double amount,
    required String purpose,
    required int durationMonths,
    String? groupId,
  });
  Future<LoanEntity> repayLoan({required String loanId, required double amount});
}
