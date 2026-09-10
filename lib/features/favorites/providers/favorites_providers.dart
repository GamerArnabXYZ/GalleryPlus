import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/favorites_repository.dart';
import '../../gallery/data/gallery_repository.dart';
import '../../gallery/providers/gallery_providers.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._repo) : super(_repo.allFavoriteIds());

  final FavoritesRepository _repo;

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    state = _repo.allFavoriteIds();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.allFavoriteIds();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(ref.watch(favoritesRepositoryProvider)),
);

/// Resolves favorite ids into full AssetEntity objects.
///
/// photo_manager doesn't offer a lightweight "get asset by id" lookup, so
/// we fetch the full "All Photos" album once and filter client-side. Fine
/// for a typical favorites list; documented here as a known tradeoff for
/// very large libraries.
final favoriteAssetsProvider = FutureProvider<List<AssetEntity>>((ref) async {
  final ids = ref.watch(favoritesProvider);
  if (ids.isEmpty) return [];

  final repo = ref.watch(galleryRepositoryProvider);
  final album = await repo.getAllAlbum(GallerySortOption.dateNewest);
  if (album == null) return [];

  final all = await repo.getAllAssets(album);
  return all.where((a) => ids.contains(a.id)).toList();
});
