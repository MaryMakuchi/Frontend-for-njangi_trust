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

  // Play schedule (optional).
  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _weekOfMonthOptions = [
    'first',
    'second',
    'third',
    'fourth',
    'last',
  ];
  String? _playFrequency; // 'weekly' | 'monthly'
  int? _playWeekday; // 0=Mon..6=Sun
  String? _playWeekOfMonth;
  TimeOfDay? _playDeadlineTime;

  bool get _scheduleStarted =>
      _playFrequency != null ||
      _playWeekday != null ||
      _playWeekOfMonth != null ||
      _playDeadlineTime != null;

  String? _validateSchedule() {
    if (!_scheduleStarted) return null;
    if (_playFrequency == null) return 'Select a play frequency';
    if (_playWeekday == null) return 'Select a play weekday';
    if (_playFrequency == 'monthly' && _playWeekOfMonth == null) {
      return 'Select a week of the month';
    }
    return null;
  }

  String? _deadlineTimeString() {
    final t = _playDeadlineTime;
    if (t == null) return null;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

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
    final scheduleError = _validateSchedule();
    if (scheduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleError)),
      );
      return;
    }
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
            playFrequency: _playFrequency,
            playWeekday: _playWeekday,
            playWeekOfMonth:
                _playFrequency == 'monthly' ? _playWeekOfMonth : null,
            playDeadlineTime: _deadlineTimeString(),
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Play Schedule (optional)',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Set when members are expected to play (contribute) each cycle.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _playFrequency,
                decoration: const InputDecoration(labelText: 'Play Frequency'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setState(() {
                  _playFrequency = v;
                  if (v != 'monthly') _playWeekOfMonth = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _playWeekday,
                decoration: const InputDecoration(labelText: 'Play Weekday'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Select day')),
                  for (var i = 0; i < _weekdayNames.length; i++)
                    DropdownMenuItem<int?>(
                      value: i,
                      child: Text(_weekdayNames[i]),
                    ),
                ],
                onChanged: (v) => setState(() => _playWeekday = v),
              ),
              if (_playFrequency == 'monthly') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _playWeekOfMonth,
                  decoration:
                      const InputDecoration(labelText: 'Week of Month'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Select week')),
                    for (final w in _weekOfMonthOptions)
                      DropdownMenuItem<String?>(
                        value: w,
                        child: Text('${w[0].toUpperCase()}${w.substring(1)}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _playWeekOfMonth = v),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Deadline Time'),
                subtitle: Text(
                  _playDeadlineTime == null
                      ? 'Not set'
                      : _playDeadlineTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime:
                        _playDeadlineTime ?? const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (time != null) setState(() => _playDeadlineTime = time);
                },
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
