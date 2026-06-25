import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/group_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'group_preview_screen.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(groupSearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(groupSearchQueryProvider);
    final searchResultsAsync = ref.watch(groupSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Groups',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a group by name and request to join.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Search groups by name',
              controller: _searchController,
              hint: 'e.g. Family Savings Circle',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            if (searchQuery.trim().isNotEmpty)
              searchResultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Error: $e'),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No groups found.'),
                    );
                  }
                  return Column(
                    children: results
                        .map((g) => _GroupSearchResultTile(group: g))
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
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

class _GroupSearchResultTile extends StatelessWidget {
  const _GroupSearchResultTile({required this.group});

  final GroupSearchResultEntity group;

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupPreviewScreen(groupId: group.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openPreview(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${group.memberCount}/${group.maxMembers} members',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
