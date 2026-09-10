import 'package:flutter/material.dart';

import '../../data/gallery_repository.dart';
import '../../../../core/theme/app_theme.dart';

Future<GallerySortOption?> showSortOptionsSheet(
  BuildContext context,
  GallerySortOption current,
) {
  return showModalBottomSheet<GallerySortOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => _SortSheet(current: current),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});
  final GallerySortOption current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            _tile(context, GallerySortOption.dateNewest, Icons.arrow_downward, 'Date (Newest first)'),
            _tile(context, GallerySortOption.dateOldest, Icons.arrow_upward, 'Date (Oldest first)'),
            _tile(context, GallerySortOption.sizeLargest, Icons.arrow_downward, 'Size (Largest first)'),
            _tile(context, GallerySortOption.sizeSmallest, Icons.arrow_upward, 'Size (Smallest first)'),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    GallerySortOption option,
    IconData icon,
    String label,
  ) {
    final selected = option == current;
    return ListTile(
      minVerticalPadding: 16,
      leading: Icon(icon),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: () => Navigator.of(context).pop(option),
    );
  }
}
