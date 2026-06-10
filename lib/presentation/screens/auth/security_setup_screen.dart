import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() =>
      _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  bool _biometricsEnabled = true;
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _isLoading = true);
    final storage = ref.read(secureStorageProvider);
    if (_pinController.text.length == AppConstants.pinLength) {
      await storage.savePin(_pinController.text);
    }
    await storage.setBiometricsEnabled(_biometricsEnabled);
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.securitySetup)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protect Your Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Enable Biometrics'),
                    ),
                    Switch(
                      value: _biometricsEnabled,
                      onChanged: (v) => setState(() => _biometricsEnabled = v),
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Set 4-digit PIN',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              PinCodeTextField(
                appContext: context,
                length: AppConstants.pinLength,
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
              ),
              const Spacer(),
              CustomButton(
                label: 'Complete Setup',
                isLoading: _isLoading,
                onPressed: _complete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
