import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/kyc_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/security_setup_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/verify_phone_screen.dart';
import '../screens/contributions/contribution_screen.dart';
import '../screens/contributions/make_contribution_screen.dart';
import '../screens/contributions/payment_success_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/groups/group_details_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/groups/join_group_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/loans/request_loan_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/profile/blockchain_ledger_screen.dart';
import '../screens/profile/mri_score_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/savings_screen.dart';
import '../screens/profile/social_fund_screen.dart';
import '../screens/profile/wallet_accounts_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const verifyPhone = '/verify-phone';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const kyc = '/kyc';
  static const securitySetup = '/security-setup';
  static const home = '/home';
  static const groups = '/groups';
  static const groupDetails = '/groups/:id';
  static const createGroup = '/groups/create';
  static const joinGroup = '/groups/join';
  static const contributions = '/contributions';
  static const makeContribution = '/contributions/pay';
  static const paymentSuccess = '/contributions/success';
  static const loans = '/loans';
  static const requestLoan = '/loans/request';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const mriScore = '/mri-score';
  static const savings = '/savings';
  static const socialFund = '/social-fund';
  static const blockchainLedger = '/blockchain-ledger';
  static const personalInfo = '/personal-info';
  static const walletAccounts = '/wallet-accounts';
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;
      final location = state.matchedLocation;

      final isPublicRoute = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.verifyPhone,
        AppRoutes.verifyEmail,
        AppRoutes.forgotPassword,
        AppRoutes.kyc,
        AppRoutes.securitySetup,
      ].contains(location);

      final isPostRegisterRoute = [
        AppRoutes.register,
        AppRoutes.verifyPhone,
        AppRoutes.verifyEmail,
        AppRoutes.kyc,
        AppRoutes.securitySetup,
      ].contains(location);

      if (isLoading && location == AppRoutes.splash) return null;

      if (!isAuthenticated && !isPublicRoute) return AppRoutes.login;
      if (isAuthenticated &&
          isPublicRoute &&
          !isPostRegisterRoute &&
          location != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyPhone,
        builder: (_, __) => const VerifyPhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.kyc,
        builder: (_, __) => const KycScreen(),
      ),
      GoRoute(
        path: AppRoutes.securitySetup,
        builder: (_, __) => const SecuritySetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.groups,
            pageBuilder: (_, state) => const NoTransitionPage(
              child: GroupsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateGroupScreen(),
              ),
              GoRoute(
                path: 'join',
                builder: (_, __) => const JoinGroupScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => GroupDetailsScreen(
                  groupId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.contributions,
            pageBuilder: (_, state) => const NoTransitionPage(
              child: ContributionScreen(),
            ),
            routes: [
              GoRoute(
                path: 'pay',
                builder: (_, __) => const MakeContributionScreen(),
              ),
              GoRoute(
                path: 'success',
                builder: (_, __) => const PaymentSuccessScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.loans,
            pageBuilder: (_, state) => const NoTransitionPage(
              child: LoansScreen(),
            ),
            routes: [
              GoRoute(
                path: 'request',
                builder: (_, __) => const RequestLoanScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mriScore,
        builder: (_, __) => const MriScoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.savings,
        builder: (_, __) => const SavingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.socialFund,
        builder: (_, __) => const SocialFundScreen(),
      ),
      GoRoute(
        path: AppRoutes.blockchainLedger,
        builder: (_, __) => const BlockchainLedgerScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.walletAccounts,
        builder: (_, __) => const WalletAccountsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
