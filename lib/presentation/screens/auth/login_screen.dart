import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  String _countryCode = '+237';
  bool _isPhoneLogin = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isPhoneLogin) {
        await ref.read(authStateProvider.notifier).loginWithPhone(
              '$_countryCode${_phoneNumberController.text.trim()}',
              _passwordController.text,
            );
      } else {
        await ref.read(authStateProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text,
            );
      }
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to ${AppStrings.appName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _LoginTab(
                        label: 'Email',
                        isSelected: !_isPhoneLogin,
                        onTap: () => setState(() => _isPhoneLogin = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LoginTab(
                        label: 'Phone',
                        isSelected: _isPhoneLogin,
                        onTap: () => setState(() => _isPhoneLogin = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isPhoneLogin)
                  _PhoneInput(
                    countryCode: _countryCode,
                    phoneController: _phoneNumberController,
                    onCountryCodeChanged: (value) =>
                        setState(() => _countryCode = value),
                  )
                else
                  CustomTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.mediumGray,
                    ),
                  ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.mediumGray,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text(AppStrings.forgotPassword),
                  ),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  label: AppStrings.login,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text("Don't have an account? Create one"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({
    required this.countryCode,
    required this.phoneController,
    required this.onCountryCodeChanged,
  });

  final String countryCode;
  final TextEditingController phoneController;
  final ValueChanged<String> onCountryCodeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: DropdownButtonFormField<String>(
            initialValue: countryCode,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: AppConstants.countryCodes
                .map(
                  (country) => DropdownMenuItem(
                    value: country['code'],
                    child: Text(
                      '${country['flag']} ${country['code']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onCountryCodeChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            decoration: const InputDecoration(
              hintText: '6XX XXX XXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.mediumGray,
            ),
          ),
        ),
      ),
    );
  }
}
