import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _membersController = TextEditingController(text: '20');
  final _rulesController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _durationController = TextEditingController(text: '12');
  String _frequency = AppConstants.contributionFrequencies.first;
  String _pickingMode = 'random';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    _rulesController.dispose();
    _targetAmountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  int get _pickersPerCycle {
    final members = int.tryParse(_membersController.text) ?? 0;
    final duration = int.tryParse(_durationController.text) ?? 0;
    if (members <= 0 || duration <= 0) return 0;
    return (members / duration).ceil();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            name: _nameController.text.trim(),
            contributionAmount:
                double.parse(_amountController.text.replaceAll(',', '')),
            frequency: _frequency,
            maxMembers: int.parse(_membersController.text),
            startDate: _startDate,
            rules: _rulesController.text.trim().isEmpty
                ? null
                : _rulesController.text.trim(),
            targetAmount: _targetAmountController.text.trim().isEmpty
                ? null
                : double.parse(_targetAmountController.text.replaceAll(',', '')),
            durationMonths: int.parse(_durationController.text),
            pickingMode: _pickingMode,
          );
      ref.invalidate(groupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Group Name',
                controller: _nameController,
                validator: (v) => Validators.required(v, field: 'Group name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contribution Amount (CFA)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: Validators.amount,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: AppConstants.contributionFrequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Number of Members',
                controller: _membersController,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, field: 'Members'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Date'),
                subtitle: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Group Duration (months)',
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, field: 'Duration'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Target Picking Amount (CFA, optional)',
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                hint: 'The amount each member receives when it is their turn',
              ),
              if (_pickersPerCycle > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Based on $_pickersPerCycle member(s) picking per cycle '
                  '(${_membersController.text} members over '
                  '${_durationController.text} months).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Picking Order', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Random'),
                      value: 'random',
                      groupValue: _pickingMode,
                      onChanged: (v) => setState(() => _pickingMode = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Manual'),
                      value: 'manual',
                      groupValue: _pickingMode,
                      onChanged: (v) => setState(() => _pickingMode = v!),
                    ),
                  ),
                ],
              ),
              Text(
                'The picking order is assigned once the group reaches its '
                'maximum number of members.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Rules (optional)',
                controller: _rulesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Create Group',
                isLoading: _isLoading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
