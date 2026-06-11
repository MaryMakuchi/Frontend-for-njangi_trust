import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/api_helper.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loan_repository.dart';
import '../datasources/mock_data.dart';
import '../models/loan_model.dart';

class LoanRepositoryImpl implements LoanRepository {
  LoanRepositoryImpl({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  @override
  Future<List<LoanEntity>> getLoans() async {
    if (AppConstants.useMockData) return MockData.loans;

    final response = await _api.get('/loans/');
    return parseListResponse(response)
        .map((e) => LoanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<double> getMaxEligibleAmount() async {
    if (AppConstants.useMockData) {
      final mri = MockData.currentUser.mriScore;
      if (mri >= 9.0) return 500000;
      if (mri >= 8.0) return 350000;
      if (mri >= 7.0) return 200000;
      return 100000;
    }

    final response = await _api.get('/loans/eligibility/');
    final json = parseJsonResponse(response);
    return parseDouble(json['max_eligible_amount']);
  }

  @override
  Future<LoanEntity> requestLoan({
    required double amount,
    required String purpose,
    required int durationMonths,
    String? groupId,
  }) async {
    if (AppConstants.useMockData) {
      return LoanEntity(
        id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        purpose: purpose,
        durationMonths: durationMonths,
        status: LoanStatus.pending,
        interestRate: 5.0,
      );
    }

    final body = <String, dynamic>{
      'amount': amount,
      'purpose': purpose,
      'duration_months': durationMonths,
    };
    if (groupId != null) body['group_id'] = groupId;

    final response = await _api.post('/loans/request/', body: body);
    return LoanModel.fromJson(parseJsonResponse(response));
  }

  @override
  Future<LoanEntity> repayLoan({required String loanId, required double amount}) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError('Loan repayment is not available in mock mode');
    }

    final response = await _api.post('/loans/$loanId/repay/', body: {'amount': amount});
    return LoanModel.fromJson(parseJsonResponse(response));
  }
}
