import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/group_card.dart';
import '../../widgets/loading_skeleton.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        automaticallyImplyLeading: false,
      ),
      body: groupsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(height: 140, borderRadius: 16),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(groupsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No groups. Join one today',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ...groups.map(
                (g) => GroupCard(
                  group: g,
                  onTap: () => context.push('/groups/${g.id}'),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Create New Group',
                icon: Icons.add,
                onPressed: () => context.push('${AppRoutes.groups}/create'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Join a Group',
                isOutlined: true,
                icon: Icons.group_add,
                onPressed: () => context.push('${AppRoutes.groups}/join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
