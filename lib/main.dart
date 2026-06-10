import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase: set useFirebase=true after running `flutterfire configure`
  // await initializeFirebase(useFirebase: true);
  runApp(const ProviderScope(child: NjangiTrustApp()));
}

class NjangiTrustApp extends ConsumerWidget {
  const NjangiTrustApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Njangi Trust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
