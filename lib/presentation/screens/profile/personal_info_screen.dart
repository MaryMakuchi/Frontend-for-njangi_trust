import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_text_field.dart';

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoTile(label: 'Full Name', value: user?.fullName ?? '-'),
          _InfoTile(label: 'Email', value: user?.email ?? '-'),
          _InfoTile(label: 'Phone', value: user?.phone ?? '-'),
          _InfoTile(
            label: 'KYC Status',
            value: user?.isKycVerified == true ? 'Verified' : 'Pending',
          ),
          _InfoTile(label: 'MRI Score', value: user != null ? user.mriScore.toStringAsFixed(1) : '-'),
          _InfoTile(label: 'Groups', value: '${user?.groupsCount ?? 0}'),
          _InfoTile(label: 'Years Active', value: '${user?.yearsActive ?? 0}'),
          if (user?.badge != null) _InfoTile(label: 'Badge', value: user!.badge!),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Current Password',
                    controller: currentController,
                    obscureText: true,
                    validator: (v) => Validators.required(v, field: 'Current password'),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'New Password',
                    controller: newController,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm New Password',
                    controller: confirmController,
                    obscureText: true,
                    validator: (v) => Validators.confirmPassword(v, newController.text),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);
                      try {
                        await ref.read(authRepositoryProvider).changePassword(
                              currentPassword: currentController.text,
                              newPassword: newController.text,
                            );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully')),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          final message =
                              e is ApiException ? e.message : AppStrings.genericError;
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
