import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/models/trash_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../providers/trash_providers.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref, TrashEntry entry) async {
    await ref.read(trashProvider.notifier).restore(entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Restored to gallery.')));
    }
  }

  Future<void> _deleteForever(BuildContext context, WidgetRef ref, TrashEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(trashProvider.notifier).permanentlyDelete(entry);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(trashProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.delete_outline,
              title: 'Trash is empty',
              subtitle:
                  'Deleted items on Android 8-10 stay here for 30 days before being removed automatically.\n\n'
                  'On Android 11+, deleted items go to the system trash (Photos / Files app).',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceSm),
              itemBuilder: (context, index) {
                final entry = items[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppTheme.spaceSm),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: entry.isVideo
                            ? const ColoredBox(
                                color: Colors.black26,
                                child: Icon(Icons.videocam),
                              )
                            : Image.file(
                                File(entry.trashedFilePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                      ),
                    ),
                    title: Text(entry.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${entry.daysRemaining} day(s) left'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Restore',
                          onPressed: () => _restore(context, ref, entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_outlined),
                          tooltip: 'Delete forever',
                          onPressed: () => _deleteForever(context, ref, entry),
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
