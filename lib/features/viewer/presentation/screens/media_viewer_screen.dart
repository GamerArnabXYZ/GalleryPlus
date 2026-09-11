import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';

import '../../../favorites/providers/favorites_providers.dart';
import '../../../gallery/providers/album_assets_provider.dart';
import '../../../gallery/providers/gallery_providers.dart';
import '../widgets/video_player_widget.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
    this.album,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  /// Pass the source album when opened from an album/grid screen so the
  /// viewer can trigger pagination (loadMore) and keep that grid's list in
  /// sync on delete. Leave null when opened from a smaller, non-paginated
  /// list (e.g. Favorites) — deletion still works, it just won't try to
  /// sync a paginated provider that doesn't apply.
  final AssetPathEntity? album;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    final album = widget.album;
    if (album != null && index >= widget.assets.length - 3) {
      ref.read(albumAssetsProvider(album).notifier).loadMore();
    }
  }

  Future<void> _delete(AssetEntity asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
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

    await ref.read(mediaDeleteServiceProvider).deleteAssets([asset]);
    final album = widget.album;
    if (album != null) {
      ref.read(albumAssetsProvider(album).notifier).removeAssets({asset.id});
    }
    ref.read(favoritesProvider.notifier).remove(asset.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _showDetails(AssetEntity asset) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _DetailsSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final asset = widget.assets[_currentIndex];
    final isFavorite = favorites.contains(asset.id);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(asset.id),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => _showDetails(asset),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _delete(asset),
                ),
              ],
            )
          : null,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.assets.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final item = widget.assets[index];
          return _DismissiblePage(
            onDismiss: () => Navigator.of(context).pop(),
            onTapChrome: () => setState(() => _chromeVisible = !_chromeVisible),
            childBuilder: (canDismiss) => item.type == AssetType.video
                ? _VideoPage(asset: item, isActive: index == _currentIndex)
                : _ImagePage(asset: item, canDismiss: canDismiss),
          );
        },
      ),
    );
  }
}

class _DismissiblePage extends StatefulWidget {
  const _DismissiblePage({
    required this.childBuilder,
    required this.onDismiss,
    required this.onTapChrome,
  });

  /// Receives a notifier the page content can flip to `false` while it
  /// wants to own vertical drags itself (e.g. panning a zoomed-in photo),
  /// so swipe-to-dismiss only engages when the content is at rest.
  final Widget Function(ValueNotifier<bool> canDismiss) childBuilder;
  final VoidCallback onDismiss;
  final VoidCallback onTapChrome;

  @override
  State<_DismissiblePage> createState() => _DismissiblePageState();
}

class _DismissiblePageState extends State<_DismissiblePage> {
  final ValueNotifier<bool> _canDismiss = ValueNotifier<bool>(true);
  double _dragOffset = 0;
  bool _dragging = false;
  bool _gestureOwnsDrag = true;

  @override
  void dispose() {
    _canDismiss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 500)).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: widget.onTapChrome,
      onVerticalDragStart: (_) {
        _gestureOwnsDrag = _canDismiss.value;
        if (_gestureOwnsDrag) setState(() => _dragging = true);
      },
      onVerticalDragUpdate: (details) {
        if (!_gestureOwnsDrag) return;
        setState(() => _dragOffset += details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        if (!_gestureOwnsDrag) return;
        final velocity = details.primaryVelocity ?? 0;
        final shouldDismiss = _dragOffset.abs() > 120 || velocity.abs() > 800;
        setState(() => _dragging = false);
        if (shouldDismiss) {
          widget.onDismiss();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      // The Scaffold behind this is already solid black — fading the
      // dragged content's opacity (rather than trying to paint a
      // background color behind an opaque image/video) is what actually
      // produces the "swipe to fade out" effect.
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Opacity(opacity: opacity, child: widget.childBuilder(_canDismiss)),
      ),
    );
  }
}

class _ImagePage extends StatelessWidget {
  const _ImagePage({required this.asset, required this.canDismiss});
  final AssetEntity asset;
  final ValueNotifier<bool> canDismiss;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.originBytes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return PhotoView(
          imageProvider: MemoryImage(snapshot.data!),
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          heroAttributes: PhotoViewHeroAttributes(tag: asset.id),
          // Only allow the parent's swipe-to-dismiss to take vertical
          // drags while the photo is at its default (non-zoomed) scale —
          // otherwise panning around a zoomed photo would fight with it.
          scaleStateChangedCallback: (state) {
            canDismiss.value = state == PhotoViewScaleState.initial;
          },
        );
      },
    );
  }
}

class _VideoPage extends StatelessWidget {
  const _VideoPage({required this.asset, required this.isActive});
  final AssetEntity asset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return VideoPlayerWidget(file: file, isActive: isActive);
      },
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.asset});
  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Object?>>(
        future: Future.wait([asset.file, asset.titleAsync]),
        builder: (context, snapshot) {
          final file = snapshot.data?[0] as File?;
          final title = snapshot.data?[1] as String? ?? 'Untitled';
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _row('Type', asset.type == AssetType.video ? 'Video' : 'Photo'),
                _row('Dimensions', '${asset.width} x ${asset.height}'),
                _row('Date', DateFormat('d MMM yyyy, h:mm a').format(asset.createDateTime)),
                if (file != null)
                  FutureBuilder<int>(
                    future: file.length(),
                    builder: (context, sizeSnap) => _row(
                      'Size',
                      sizeSnap.hasData
                          ? '${(sizeSnap.data! / (1024 * 1024)).toStringAsFixed(2)} MB'
                          : '...',
                    ),
                  ),
                if (file != null) _row('Path', file.path),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
