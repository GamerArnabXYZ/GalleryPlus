import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../viewer/presentation/screens/media_viewer_screen.dart';
import '../../../gallery/presentation/widgets/media_thumbnail_tile.dart';
import '../../providers/favorites_providers.dart' show favoriteAssetsProvider;

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load favorites: $e')),
        data: (assets) {
          if (assets.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon on any photo or video to save it here.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppTheme.gridSpacing),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppTheme.gridSpacing,
              mainAxisSpacing: AppTheme.gridSpacing,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return MediaThumbnailTile(
                asset: asset,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MediaViewerScreen(
                        assets: assets,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
