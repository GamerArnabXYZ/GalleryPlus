// StateNotifier/StateNotifierProvider moved to "legacy" in Riverpod 3.0 —
// this import alone covers everything this file needs (Ref, family, etc.
// come through transitively, so a separate base-package import is unused).
import 'package:flutter_riverpod/legacy.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/gallery_repository.dart';
import 'gallery_providers.dart';

class AlbumAssetsState {
  const AlbumAssetsState({
    this.assets = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.isCustomSorted = false,
  });

  final List<AssetEntity> assets;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  /// True once the list has been fully loaded and re-sorted client-side
  /// (by size, or by date-oldest-first) — pagination (loadMore) pauses
  /// while this is true since the whole album is already in memory.
  final bool isCustomSorted;

  AlbumAssetsState copyWith({
    List<AssetEntity>? assets,
    bool? isLoading,
    bool? hasMore,
    Object? error,
    bool? isCustomSorted,
  }) {
    return AlbumAssetsState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isCustomSorted: isCustomSorted ?? this.isCustomSorted,
    );
  }
}

/// One controller per album — lazily loads a page at a time as the grid
/// scrolls, keeping memory/CPU use low even for huge camera rolls.
class AlbumAssetsNotifier extends StateNotifier<AlbumAssetsState> {
  AlbumAssetsNotifier(this._repo, this._album) : super(const AlbumAssetsState()) {
    loadInitial();
  }

  final GalleryRepository _repo;
  final AssetPathEntity _album;
  int _page = 0;

  /// Default order: newest-first, exactly as the album was queried
  /// (matches the app-wide default sort).
  Future<void> loadInitial() async {
    state = const AlbumAssetsState(isLoading: true);
    try {
      final assets = await _repo.getAssetsPage(_album, page: 0);
      _page = 0;
      state = AlbumAssetsState(
        assets: assets,
        hasMore: assets.length == GalleryRepository.pageSize,
      );
    } catch (e) {
      state = AlbumAssetsState(error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.isCustomSorted) return;
    state = state.copyWith(isLoading: true);
    try {
      _page++;
      final next = await _repo.getAssetsPage(_album, page: _page);
      state = state.copyWith(
        assets: [...state.assets, ...next],
        isLoading: false,
        hasMore: next.length == GalleryRepository.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<List<AssetEntity>> _ensureFullyLoaded() async {
    return state.hasMore ? _repo.getAllAssets(_album) : state.assets;
  }

  /// Opt-in: fetches every remaining asset then sorts by file size.
  /// Expensive on huge albums — only call from an explicit user action.
  Future<void> sortBySize({required bool largestFirst}) async {
    state = state.copyWith(isLoading: true);
    try {
      final all = await _ensureFullyLoaded();
      final sorted = await _repo.sortBySize(all, largestFirst: largestFirst);
      state = state.copyWith(
        assets: sorted,
        isLoading: false,
        hasMore: false,
        isCustomSorted: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// newestFirst==true matches the default query order already, so that
  /// case just re-runs the normal paginated load; oldestFirst requires the
  /// full list in memory to reverse chronologically.
  Future<void> sortByDate({required bool newestFirst}) async {
    if (newestFirst) {
      await loadInitial();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final all = await _ensureFullyLoaded();
      final sorted = [...all]
        ..sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
      state = state.copyWith(
        assets: sorted,
        isLoading: false,
        hasMore: false,
        isCustomSorted: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void removeAssets(Set<String> ids) {
    state = state.copyWith(
      assets: state.assets.where((a) => !ids.contains(a.id)).toList(),
    );
  }
}

final albumAssetsProvider = StateNotifierProvider.family<AlbumAssetsNotifier,
    AlbumAssetsState, AssetPathEntity>((ref, album) {
  final repo = ref.watch(galleryRepositoryProvider);
  return AlbumAssetsNotifier(repo, album);
});
