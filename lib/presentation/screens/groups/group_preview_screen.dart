import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/api_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/njangi_hype.dart';
import '../../../domain/entities/group_preview_entity.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';

/// Read-only preview of a group shown before a user requests to join, so they
/// can confirm it's the right group. Reached from the search results on the
/// join-group screen.
class GroupPreviewScreen extends ConsumerWidget {
  const GroupPreviewScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(groupPreviewProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Group Preview')),
      body: previewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
        ),
        data: (preview) => _PreviewBody(groupId: groupId, preview: preview),
      ),
    );
  }
}

class _PreviewBody extends ConsumerStatefulWidget {
  const _PreviewBody({required this.groupId, required this.preview});

  final String groupId;
  final GroupPreviewEntity preview;

  @override
  ConsumerState<_PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends ConsumerState<_PreviewBody> {
  bool _isLoading = false;
  bool _requested = false;

  Future<void> _requestToJoin() async {
    setState(() => _isLoading = true);
    try {
      final detail = await ref.read(groupRepositoryProvider).joinGroup(
            groupId: widget.groupId,
          );
      if (mounted) {
        setState(() {
          _requested = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = e is ApiException ? e.message : AppStrings.genericError;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purpleSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  'Contribution',
                  Formatters.currency(p.contributionAmount),
                ),
                _InfoRow('Members', '${p.memberCount}/${p.maxMembers}'),
                if (p.playFrequency != null && p.playFrequency!.isNotEmpty)
                  _InfoRow('Frequency', p.playFrequency!),
                if (p.nextPlayDue != null)
                  _InfoRow('Next play due', formatDueDateTime(p.nextPlayDue!)),
                if (p.presidentName != null && p.presidentName!.isNotEmpty)
                  _InfoRow('President', p.presidentName!),
              ],
            ),
          ),
          if (p.rules != null && p.rules!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Rules & Description',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.rules!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 32),
          _buildAction(context, p),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, GroupPreviewEntity p) {
    if (p.isMember) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoBanner(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            text: "You're already a member",
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('${AppRoutes.groups}/${p.id}'),
            child: const Text('Open Group'),
          ),
        ],
      );
    }

    if (p.hasPendingRequest || _requested) {
      return const _InfoBanner(
        icon: Icons.hourglass_top,
        color: AppColors.warning,
        text: 'Request pending',
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _requestToJoin,
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Request to Join'),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
