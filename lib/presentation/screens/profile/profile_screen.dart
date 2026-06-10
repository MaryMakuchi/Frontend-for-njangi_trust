import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user?.fullName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Member',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                if (user?.badge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user!.badge!,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(
                label: 'Groups',
                value: '${user?.groupsCount ?? 0}',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Years Active',
                value: '${user?.yearsActive ?? 0}',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Global Rank',
                value: '#${user?.globalRank ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.verified_user_outlined,
            title: 'KYC Verification',
            trailing: user?.isKycVerified == true
                ? const Text('Verified', style: TextStyle(color: AppColors.success))
                : const Text('Pending', style: TextStyle(color: AppColors.warning)),
            onTap: () => context.push(AppRoutes.kyc),
          ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet & Accounts',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () => context.push(AppRoutes.securitySetup),
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _MenuItem(
            icon: Icons.savings_outlined,
            title: 'Savings Overview',
            onTap: () => context.push(AppRoutes.savings),
          ),
          _MenuItem(
            icon: Icons.analytics_outlined,
            title: 'MRI Score',
            onTap: () => context.push(AppRoutes.mriScore),
          ),
          _MenuItem(
            icon: Icons.link,
            title: 'Blockchain Ledger',
            onTap: () => context.push(AppRoutes.blockchainLedger),
          ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
