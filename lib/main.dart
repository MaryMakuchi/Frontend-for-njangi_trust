import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Once the user is authenticated, register this device for push and route
    // taps on notifications to the relevant screen. Runs once per session.
    ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      if (user != null && !_pushInitialized) {
        _pushInitialized = true;
        ref.read(notificationServiceProvider).initialize(
              onOpen: (message) => _handlePushTap(router, message.data),
            );
      } else if (user == null) {
        _pushInitialized = false;
      }
    });

    return MaterialApp.router(
      title: 'Njangi Trust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
