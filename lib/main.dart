import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/services/firebase_init.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/user_entity.dart';
import 'presentation/providers/providers.dart';
import 'presentation/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Best-effort: enables push when Firebase has been configured for the
  // platform (run `flutterfire configure`); a no-op otherwise.
  await initializeFirebase();
  runApp(const ProviderScope(child: NjangiTrustApp()));
}

class NjangiTrustApp extends ConsumerStatefulWidget {
  const NjangiTrustApp({super.key});

  @override
  ConsumerState<NjangiTrustApp> createState() => _NjangiTrustAppState();
}

class _NjangiTrustAppState extends ConsumerState<NjangiTrustApp> {
  bool _pushInitialized = false;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _initPushFor(GoRouter router) {
    if (_pushInitialized) return;
    _pushInitialized = true;
    ref.read(notificationServiceProvider).initialize(
          onOpen: (message) => _handlePushTap(router, message.data),
          onForeground: (message) => _showForegroundBanner(router, message),
        );
  }

  /// Show an in-app banner when a push arrives while the app is open, since FCM
  /// suppresses the system notification in the foreground. Tapping "View"
  /// routes to the same screen a tapped system notification would.
  void _showForegroundBanner(GoRouter router, RemoteMessage message) {
    final notif = message.notification;
    final title = notif?.title ?? 'New notification';
    final body = notif?.body ?? '';

    // Keep the unread badge/count in sync with the freshly-arrived message.
    ref.invalidate(unreadNotificationCountProvider);

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.primary,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: const TextStyle(color: AppColors.white),
                ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.white,
            onPressed: () => _handlePushTap(router, message.data),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Once the user is authenticated, register this device for push and route
    // taps on notifications to the relevant screen. Runs once per session.
    ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      if (user != null) {
        _initPushFor(router);
      } else if (user == null) {
        _pushInitialized = false;
      }
    });

    // Handle the case where the session was already restored before the
    // listener above attached (auto-login on app start) — register now.
    if (ref.read(authStateProvider).valueOrNull != null) {
      _initPushFor(router);
    }

    return MaterialApp.router(
      title: 'Nkap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
    );
  }

  /// Navigate based on a push payload, mirroring the in-app notification
  /// routing. Falls back to the dashboard so a tap never dead-ends.
  void _handlePushTap(GoRouter router, Map<String, dynamic> data) {
    final targetType = data['target_type']?.toString() ?? '';
    final targetId = data['target_id']?.toString() ?? '';
    final targetView = data['target_view']?.toString() ?? '';

    switch (targetType) {
      case 'group':
        if (targetId.isNotEmpty) {
          final tabQuery = targetView.isNotEmpty ? '?tab=$targetView' : '';
          router.push('${AppRoutes.groups}/$targetId$tabQuery');
        } else {
          router.go(AppRoutes.home);
        }
        break;
      case 'loan':
        router.push(AppRoutes.loans);
        break;
      case 'transaction':
        router.push(AppRoutes.blockchainLedger);
        break;
      default:
        router.go(AppRoutes.home);
        break;
    }
  }
}
