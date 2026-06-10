import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _items = [
    _KycItem('ID Card (Front)', Icons.credit_card, false),
    _KycItem('ID Card (Back)', Icons.credit_card_outlined, false),
    _KycItem('Selfie Verification', Icons.face, false),
    _KycItem('Proof of Address', Icons.home_outlined, false),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((i) => i.completed).length;
    final progress = completed / _items.length;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.kycVerification)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete all steps to unlock full platform features',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text('$completed of ${_items.length} completed'),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return _KycTile(
                      item: item,
                      onTap: () {
                        setState(() => _items[i] = item.copyWith(completed: true));
                      },
                    );
                  },
                ),
              ),
              CustomButton(
                label: completed == _items.length ? 'Continue' : 'Skip for Now',
                onPressed: () => context.go(AppRoutes.securitySetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycItem {
  const _KycItem(this.title, this.icon, this.completed);
  final String title;
  final IconData icon;
  final bool completed;

  _KycItem copyWith({bool? completed}) =>
      _KycItem(title, icon, completed ?? this.completed);
}

class _KycTile extends StatelessWidget {
  const _KycTile({required this.item, required this.onTap});

  final _KycItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.completed ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: item.completed ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.title)),
            Icon(
              item.completed ? Icons.check_circle : Icons.upload_outlined,
              color: item.completed ? AppColors.success : AppColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }
}
