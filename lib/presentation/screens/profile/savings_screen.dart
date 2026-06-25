import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/group_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/group_savings_panel.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String? _selectedGroupId;

  bool _isPresident(WidgetRef ref, GroupEntity group) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return false;
    final membership = group.members.where((m) => m.id == user.id);
    return membership.isNotEmpty && membership.first.role == GroupRole.president;
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You are not a member of any group yet. Join or create a '
                  'group to start saving.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedId = _selectedGroupId ?? groups.first.id;
          final selectedGroup = groups.firstWhere(
            (g) => g.id == selectedId,
            orElse: () => groups.first,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupSavingsProvider(selectedGroup.id));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groups.length > 1) ...[
                    Text('Group', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroup.id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedGroupId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  GroupSavingsPanel(
                    groupId: selectedGroup.id,
                    isPresident: _isPresident(ref, selectedGroup),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
