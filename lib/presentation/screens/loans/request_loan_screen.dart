import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RequestLoanScreen extends ConsumerStatefulWidget {
  const RequestLoanScreen({super.key});

  @override
  ConsumerState<RequestLoanScreen> createState() => _RequestLoanScreenState();
}

class _RequestLoanScreenState extends ConsumerState<RequestLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _duration = 3;
  String? _groupId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(loanRepositoryProvider).requestLoan(
            amount: double.parse(_amountController.text.replaceAll(',', '')),
            purpose: _purposeController.text.trim(),
            durationMonths: _duration,
            groupId: _groupId,
          );
      ref.invalidate(loansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan request submitted!')),
        );
        context.pop();
      }
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
    final maxAmountAsync = ref.watch(maxLoanAmountProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Loan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              maxAmountAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (max) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.purpleSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'You are eligible to request up to ${Formatters.currency(max)} '
                    'based on your MRI Score.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              CustomTextField(
                label: 'Amount (CFA)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: (value) {
                  final basic = Validators.amount(value);
                  if (basic != null) return basic;
                  final amount = double.parse(value!.replaceAll(',', ''));
                  final max = maxAmountAsync.valueOrNull;
                  if (max != null && amount > max) {
                    return 'You cannot request above your eligibility of '
                        '${Formatters.currency(max)}.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              Builder(builder: (context) {
                final max = maxAmountAsync.valueOrNull;
                final text = _amountController.text.replaceAll(',', '');
                final amount = double.tryParse(text);
                if (max != null && amount != null && amount > max) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'You cannot request above your eligibility of '
                        '${Formatters.currency(max)}.',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              groupsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (groups) {
                  if (groups.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String?>(
                      value: _groupId,
                      decoration: const InputDecoration(
                        labelText: 'Borrowing From (Group)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General (no group)'),
                        ),
                        ...groups.map(
                          (g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _groupId = v),
                    ),
                  );
                },
              ),
              CustomTextField(
                label: 'Purpose',
                controller: _purposeController,
                validator: (v) => Validators.required(v, field: 'Purpose'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _duration,
                decoration: const InputDecoration(labelText: 'Duration (months)'),
                items: [1, 3, 6, 12]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m months')))
                    .toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Submit Request',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
