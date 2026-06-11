import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/contribution_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../data/repositories/loan_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/contribution_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_message_entity.dart';
import '../../domain/entities/linked_account_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/social_fund_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/contribution_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/wallet_repository.dart';

// Services
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(storage: ref.watch(secureStorageProvider)),
);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
    api: ref.watch(apiServiceProvider),
  ),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final contributionRepositoryProvider = Provider<ContributionRepository>(
  (ref) => ContributionRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(api: ref.watch(apiServiceProvider)),
);
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(api: ref.watch(apiServiceProvider)),
);

// Auth state
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  final AuthRepository _repository;

  Future<void> _checkAuth() async {
    try {
      final isAuth = await _repository.isAuthenticated();
      if (isAuth) {
        final user = await _repository.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithPhone(String phone, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.loginWithPhone(phone: phone, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      // Keep existing state if refresh fails.
    }
  }
}

// Data providers
final dashboardProvider = FutureProvider<DashboardEntity>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final groupsProvider = FutureProvider<List<GroupEntity>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});

final contributionsProvider = FutureProvider<List<ContributionEntity>>((ref) {
  return ref.watch(contributionRepositoryProvider).getContributions();
});

final loansProvider = FutureProvider<List<LoanEntity>>((ref) {
  return ref.watch(loanRepositoryProvider).getLoans();
});

final notificationsProvider = FutureProvider<List<NotificationEntity>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

final maxLoanAmountProvider = FutureProvider<double>((ref) {
  return ref.watch(loanRepositoryProvider).getMaxEligibleAmount();
});

final transactionsProvider = FutureProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).getTransactions(status: 'verified');
});

final savingsHistoryProvider = FutureProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).getTransactions(
        type: 'savings_deposit,savings_withdrawal',
      );
});

final linkedAccountsProvider = FutureProvider<List<LinkedAccountEntity>>((ref) {
  return ref.watch(walletRepositoryProvider).getLinkedAccounts();
});

final groupSocialFundsProvider =
    FutureProvider.family<List<SocialFundEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getSocialFunds(groupId);
});

final groupMessagesProvider =
    FutureProvider.family<List<GroupMessageEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupMessages(groupId);
});

// Onboarding flag
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

// Whether wallet/savings balances are currently revealed (PIN-gated)
final balanceVisibleProvider = StateProvider<bool>((ref) => false);

// Last payment result for success screen
final lastPaymentProvider = StateProvider<TransactionEntity?>((ref) => null);
