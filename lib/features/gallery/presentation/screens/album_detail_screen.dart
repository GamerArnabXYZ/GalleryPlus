import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../favorites/providers/favorites_providers.dart';
import '../../../viewer/presentation/screens/media_viewer_screen.dart';
import '../../data/gallery_repository.dart';
import '../../data/media_delete_service.dart';
import '../../providers/album_assets_provider.dart';
import '../../providers/gallery_providers.dart';
import '../widgets/media_thumbnail_tile.dart';
import '../widgets/sort_options_sheet.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({super.key, required this.album, required this.title});

  final AssetPathEntity album;
  final String title;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  GallerySortOption _localSort = GallerySortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 800) {
      ref.read(albumAssetsProvider(widget.album).notifier).loadMore();
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(List<AssetEntity> allAssets) async {
    final selected =
        allAssets.where((a) => _selectedIds.contains(a.id)).toList();
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selected.length} item(s)?'),
        content: const Text(
          'Items move to GalleryPlus Trash and can be restored within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final outcome =
        await ref.read(mediaDeleteServiceProvider).deleteAssets(selected);
    ref.read(albumAssetsProvider(widget.album).notifier).removeAssets(_selectedIds);
    for (final id in _selectedIds) {
      ref.read(favoritesProvider.notifier).remove(id);
    }

    if (!mounted) return;
    final message = switch (outcome) {
      DeleteOutcome.movedToTrash => 'Moved to GalleryPlus trash.',
      DeleteOutcome.failed => 'Could not delete some items.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _clearSelection();
  }

  Future<void> _favoriteSelected() async {
    final notifier = ref.read(favoritesProvider.notifier);
    for (final id in _selectedIds) {
      await notifier.toggle(id);
    }
    _clearSelection();
  }

  Future<void> _openSort() async {
    final chosen = await showSortOptionsSheet(context, _localSort);
    if (chosen == null) return;
    setState(() => _localSort = chosen);
    final notifier = ref.read(albumAssetsProvider(widget.album).notifier);
    switch (chosen) {
      case GallerySortOption.sizeLargest:
        await notifier.sortBySize(largestFirst: true);
        break;
      case GallerySortOption.sizeSmallest:
        await notifier.sortBySize(largestFirst: false);
        break;
      case GallerySortOption.dateNewest:
        await notifier.sortByDate(newestFirst: true);
        break;
      case GallerySortOption.dateOldest:
        await notifier.sortByDate(newestFirst: false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumAssetsProvider(widget.album));

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Favorite',
                  onPressed: _favoriteSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _deleteSelected(state.assets),
                ),
              ],
            )
          : AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onPressed: _openSort,
                ),
              ],
            ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AlbumAssetsState state) {
    if (state.error != null && state.assets.isEmpty) {
      return Center(
        child: Text('Failed to load: ${state.error}'),
      );
    }
    if (state.assets.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.assets.isEmpty) {
      return const Center(child: Text('No media here yet.'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.gridSpacing),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.gridSpacing,
        mainAxisSpacing: AppTheme.gridSpacing,
      ),
      itemCount: state.assets.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.assets.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceSm),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final asset = state.assets[index];
        return MediaThumbnailTile(
          asset: asset,
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(asset.id),
          onTap: () {
            if (_selectionMode) {
              _toggleSelect(asset.id);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MediaViewerScreen(
                    assets: state.assets,
                    initialIndex: index,
                    album: widget.album,
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!_selectionMode) _enterSelection(asset.id);
          },
        );
      },
    );
  }
}
