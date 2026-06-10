import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';

class SocialFundScreen extends ConsumerWidget {
  const SocialFundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Social Fund')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dashboard) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    const Text('Community Social Fund'),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(dashboard.socialFundBalance),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency support for group members',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CustomButton(
                label: 'Contribute to Fund',
                onPressed: () => context.push('${AppRoutes.contributions}/pay'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Request Emergency Loan',
                isOutlined: true,
                onPressed: () => context.push('${AppRoutes.loans}/request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
