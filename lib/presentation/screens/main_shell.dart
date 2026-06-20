import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/providers.dart';
import '../routes/app_router.dart';

const _kIdleTimeout = Duration(minutes: 1);
const _kWarningDuration = Duration(seconds: 10);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _idleTimer;
  Timer? _logoutTimer;
  ScaffoldMessengerState? _messengerRef;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _logoutTimer?.cancel();
    _logoutTimer = null;
    _messengerRef?.hideCurrentSnackBar();
    _idleTimer = Timer(_kIdleTimeout - _kWarningDuration, _showWarning);
  }

  void _showWarning() {
    if (!mounted) return;
    _messengerRef = ScaffoldMessenger.of(context);
    _messengerRef?.showSnackBar(
      SnackBar(
        duration: _kWarningDuration,
        content: const Text('You will be logged out in 10 seconds due to inactivity.'),
        action: SnackBarAction(
          label: 'Stay',
          onPressed: _resetTimer,
        ),
        backgroundColor: AppColors.indigo,
      ),
    );
    _logoutTimer = Timer(_kWarningDuration, _autoLogout);
  }

  Future<void> _autoLogout() async {
    if (!mounted) return;
    _messengerRef?.hideCurrentSnackBar();
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.groups)) return 1;
    if (location.startsWith(AppRoutes.contributions)) return 2;
    if (location.startsWith(AppRoutes.loans)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.groups);
      case 2:
        context.go(AppRoutes.contributions);
      case 3:
        context.go(AppRoutes.loans);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: Scaffold(
        body: Column(
          children: [
            if (!isOnline) const _OfflineBanner(),
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: AppStrings.home,
                    isSelected: index == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.groups_rounded,
                    label: AppStrings.groups,
                    isSelected: index == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                  _NavItem(
                    icon: Icons.payments_rounded,
                    label: AppStrings.contributions,
                    isSelected: index == 2,
                    onTap: () => _onTap(context, 2),
                    isFab: true,
                  ),
                  _NavItem(
                    icon: Icons.account_balance_rounded,
                    label: AppStrings.loans,
                    isSelected: index == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: AppStrings.profile,
                    isSelected: index == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isFab = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFab;

  @override
  Widget build(BuildContext context) {
    if (isFab) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.accentGradient
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.white, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.lightGray,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.lightGray,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.cloud_off, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'You are offline — showing saved data',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
