import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/gallery_repository.dart';
import '../../providers/gallery_providers.dart';
import 'album_detail_screen.dart';

class AlbumsListScreen extends ConsumerWidget {
  const AlbumsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load albums: $e')),
        data: (albums) {
          // "All Photos" already has its own tab — skip it here.
          final filtered = albums.where((a) => !a.isAll).toList();
          if (filtered.isEmpty) {
            return const EmptyState(
              icon: Icons.photo_album_outlined,
              title: 'No albums found',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spaceMd,
              mainAxisSpacing: AppTheme.spaceMd,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _AlbumCard(album: filtered[index]),
          );
        },
      ),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  const _AlbumCard({required this.album});
  final AssetPathEntity album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(album: album, title: album.name),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<List<AssetEntity>>(
                future: ref
                    .read(galleryRepositoryProvider)
                    .getAssetsPage(album, page: 0, size: 1),
                builder: (context, snapshot) {
                  final list = snapshot.data;
                  final cover = (list != null && list.isNotEmpty) ? list.first : null;
                  if (cover == null) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    );
                  }
                  return FutureBuilder<Uint8List?>(
                    future: cover.thumbnailDataWithSize(const ThumbnailSize.square(300)),
                    builder: (context, thumbSnap) {
                      final bytes = thumbSnap.data;
                      if (bytes == null) {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        );
                      }
                      return Image.memory(bytes, fit: BoxFit.cover);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snap) => Text(
              snap.hasData ? '${snap.data} items' : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
