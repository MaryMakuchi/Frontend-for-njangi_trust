import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/local_cache.dart';
import '../../core/services/notification_service.dart';
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
import '../../domain/entities/due_date_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_preview_entity.dart';
import '../../domain/entities/mri_entity.dart';
import '../../domain/entities/group_message_entity.dart';
import '../../domain/entities/linked_account_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/membership_request_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/reconciliation_entity.dart';
import '../../domain/entities/savings_entity.dart';
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

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache());

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Whether the device is currently online. Defaults to true until the first
/// reading arrives, so the UI doesn't flash an offline banner on launch.
final connectivityProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChange,
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
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(notificationRepositoryProvider)),
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
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  final Ref _ref;

  /// Clears every user-scoped provider so one account never shows another
  /// account's cached data after a login/register/logout transition.
  void _resetUserData() {
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(groupsProvider);
    _ref.invalidate(contributionsProvider);
    _ref.invalidate(loansProvider);
    _ref.invalidate(maxLoanAmountProvider);
    _ref.invalidate(pendingLoanVotesProvider);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(savingsHistoryProvider);
    _ref.invalidate(linkedAccountsProvider);
    _ref.invalidate(mriHistoryProvider);
    _ref.invalidate(dueDatesProvider);
    _ref.invalidate(groupSocialFundsProvider);
    _ref.invalidate(groupMessagesProvider);
    _ref.invalidate(groupSavingsProvider);
    _ref.invalidate(membershipRequestsProvider);
    _ref.invalidate(groupLedgerProvider);
    _ref.invalidate(groupPreviewProvider);
    _ref.invalidate(reconciliationProvider);
    // Drop offline read-cache so one account never serves another's data.
    _ref.read(localCacheProvider).clear();
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
      _resetUserData();
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
      _resetUserData();
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
      _resetUserData();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _resetUserData();
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

// Unread notification count, drives the badge on the notifications icon.
final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
});

final maxLoanAmountProvider = FutureProvider<double>((ref) {
  return ref.watch(loanRepositoryProvider).getMaxEligibleAmount();
});

final pendingLoanVotesProvider = FutureProvider<List<PendingLoanVoteEntity>>((ref) {
  return ref.watch(loanRepositoryProvider).getPendingVotes();
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

final groupSavingsProvider =
    FutureProvider.family<GroupSavingsEntity, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupSavings(groupId);
});

final membershipRequestsProvider =
    FutureProvider.family<List<MembershipRequestEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getMembershipRequests(groupId);
});

// Group search (#8) — query string updated by the join-group screen, debounced
// before being applied here.
final groupSearchQueryProvider = StateProvider<String>((ref) => '');

final groupSearchResultsProvider =
    FutureProvider<List<GroupSearchResultEntity>>((ref) {
  final query = ref.watch(groupSearchQueryProvider);
  if (query.trim().isEmpty) return Future.value(const []);
  return ref.watch(groupRepositoryProvider).searchGroups(query);
});

// Due dates, keyed by horizon ("3m"|"6m"|"12m"|"all")
final dueDatesProvider =
    FutureProvider.family<List<DueDateEntity>, String>((ref, horizon) {
  return ref.watch(groupRepositoryProvider).getDueDates(horizon: horizon);
});

// Public group preview, keyed by groupId
final groupPreviewProvider =
    FutureProvider.family<GroupPreviewEntity, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupPreview(groupId);
});

// Group ledger, keyed by ({groupId, category}) record
final groupLedgerProvider = FutureProvider.family<List<TransactionEntity>,
    ({String groupId, String category})>((ref, params) {
  return ref
      .watch(groupRepositoryProvider)
      .getGroupLedger(params.groupId, category: params.category);
});

// Treasurer-liability reconciliation, keyed by groupId
final reconciliationProvider =
    FutureProvider.family<ReconciliationEntity, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getReconciliation(groupId);
});

// MRI score history for the current user
final mriHistoryProvider = FutureProvider<MriHistoryEntity>((ref) {
  return ref.watch(authRepositoryProvider).getMriHistory();
});

// Onboarding flag — persisted so the carousel is only shown once
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(localCacheProvider).readBool('onboarding_done');
  }

  Future<void> markDone() async {
    await ref.read(localCacheProvider).writeBool('onboarding_done', true);
    state = true;
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

// Whether wallet/savings balances are currently revealed (PIN-gated).
// Persisted so the user's last visibility choice survives app restarts.
class BalanceVisibleNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(localCacheProvider).readBool('balance_visible');
  }

  Future<void> set(bool value) async {
    await ref.read(localCacheProvider).writeBool('balance_visible', value);
    state = value;
  }
}

final balanceVisibleProvider =
    NotifierProvider<BalanceVisibleNotifier, bool>(BalanceVisibleNotifier.new);

// Last payment result for success screen
final lastPaymentProvider = StateProvider<TransactionEntity?>((ref) => null);
