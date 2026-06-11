import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (Validators.required(_codeController.text, field: 'Invitation code') !=
        null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final detail = await ref.read(groupRepositoryProvider).joinGroup(
            invitationCode: _codeController.text.trim().toUpperCase(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Invitation Code',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your group president for the invitation code. Try: NJA2025',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Invitation Code',
              controller: _codeController,
              hint: 'e.g. NJA2025',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
            ),
            const Spacer(),
            CustomButton(
              label: 'Request Membership',
              isLoading: _isLoading,
              onPressed: _join,
            ),
          ],
        ),
      ),
    );
  }
}
